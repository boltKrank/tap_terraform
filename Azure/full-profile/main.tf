# TAP Multi-cluster deployment

provider "azurerm" {
  features {}


  # subscription_id = var.subscription_id
  # tap_sp
  # client_id       = var.sp_client_id
  # client_secret   = var.sp_secret
  # tenant_id       = var.sp_tenant_id

}

resource "azurerm_resource_group" "tap_resource_group" {
  name     = "${var.resource_group}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "tap-network"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.tap_resource_group.location
  resource_group_name = azurerm_resource_group.tap_resource_group.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.tap_resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.30.2.0/24"]
}

# -------------------------------------- START K8S STUFF ---------------------------------------------------

# # # # Create ACR

resource "azurerm_container_registry" "tap_acr" {
  name                = var.tap_acr_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location
  sku                 = "Standard"
  admin_enabled       = true  
}

# Non DEBUG
# locals {
#   acr_pass = azurerm_container_registry.tap_acr.admin_password
# }

# To DEBUG output
locals {
  acr_pass = nonsensitive(azurerm_container_registry.tap_acr.admin_password)  
  # acr_pass = var.acr_pass
}

# TAP full START

resource "azurerm_resource_group" "tap_full_rg" {  
  name = var.tap_full_resource_group
  location = var.location
}

resource "azurerm_public_ip" "tap-full-pip" {
    
  name                = "envoy-ip" 
  resource_group_name = var.tap_full_aks_name
  location            = azurerm_resource_group.tap_full_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
} 

resource "azurerm_kubernetes_cluster" "tap_full_aks" {
  depends_on = [
    azurerm_public_ip.tap-full-pip,
  ]  
  name                = var.tap_full_aks_name
  resource_group_name = azurerm_resource_group.tap_full_rg.name
  location            = azurerm_resource_group.tap_full_rg.location    
  dns_prefix          = var.tap_full_dns_prefix
  kubernetes_version  = var.tap_k8s_version
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = var.tap_full_vm_size    
    enable_auto_scaling = var.tap_full_autoscaling
    min_count = var.tap_full_min_node_count
    max_count = var.tap_full_max_node_count
  }

  service_principal {
    client_id = var.sp_client_id
    client_secret = var.sp_secret
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

}

# TAP full END

# -------------------------------------- END K8S STUFF  --------------------------------------------------



# -------------------------------------- START BOOTSTRAP BOX ---------------------------------------------

resource "azurerm_public_ip" "bootstrap_pip" {
  name                = "bootstrap-pip"
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location
  allocation_method   = "Static"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface" "bootstrap_nic" {  
  name                = "bootstrap-nic"
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bootstrap_pip.id
  }

}

resource "azurerm_linux_virtual_machine" "main" {  
  depends_on = [    
    azurerm_kubernetes_cluster.tap_full_aks,     
  ]
 
  name                            = "bootstrap-vm"
  resource_group_name             = azurerm_resource_group.tap_resource_group.name
  location                        = azurerm_resource_group.tap_resource_group.location
  size                            = var.bootstrap_vm_size
  admin_username                  = var.bootstrap_username
  admin_password                  = var.bootstrap_password
  disable_password_authentication = false
  
  network_interface_ids = [
    azurerm_network_interface.bootstrap_nic.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  connection {
    host     = self.public_ip_address
    user     = self.admin_username
    password = self.admin_password
  }

  # Send files:
  provisioner "file" {  
    source = "${path.cwd}/Common/" 
    destination = "/home/${var.bootstrap_username}/" 
  }


  # Seperate shell so user inherits the groupadd in the following shell to run docker as non-root
  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo groupadd docker",
      "sudo usermod -aG docker $USER",
      "echo 'END DOCKER INSTALL'",
    ]

  }
  

  # # Run commands:
  provisioner "remote-exec" { 

    # Pre-reqs: Azure CLI, Pivnet CLI, Tanzu CLI, and Cluster essentials for all clusters
    inline = [
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",   
      "az login --service-principal -u ${var.sp_client_id} -p ${var.sp_secret} --tenant ${var.sp_tenant_id}",
      "wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v${var.pivnet_version}/pivnet-linux-amd64-${var.pivnet_version}",
      "chmod 755 pivnet-linux-amd64-${var.pivnet_version}",
      "sudo mv pivnet-linux-amd64-${var.pivnet_version} /usr/local/bin/pivnet",
      "pivnet login --api-token=${var.pivnet_api_token}",
      "pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='${var.tap_version}' --glob='tanzu-framework-linux-amd64-*.tar'",
      "tar xvf tanzu-framework-*-amd64-*.tar",
      "sudo install cli/core/v${var.tanzu_cli_version}/tanzu-core-*_amd64 /usr/local/bin/tanzu",
      "export TANZU_CLI_NO_INIT=true",
      "tanzu version",
      "tanzu plugin install --local cli all",
      "rm -f tanzu-framework-*-amd64-*.tar",
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",      
      "docker login ${var.tap_acr_name}.azurecr.io -u ${var.tap_acr_name} -p ${local.acr_pass}",
      "docker login ${var.tanzu_registry_hostname} -u ${var.tanzu_registry_username} -p ${var.tanzu_registry_password}",  
      "cd",      
    ]     
  }

  # imgpkg
  provisioner "remote-exec" {
    inline = [
      "wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz",
      "sudo tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz",
      "export PATH=$PATH:/usr/local/go/bin",
      "git clone https://github.com/boltKrank/imgpkg.git",
      "cd $HOME/imgpkg",
      "$HOME/imgpkg/hack/build.sh",
      "sudo cp $HOME/imgpkg/imgpkg /usr/local/bin/imgpkg",    
      "imgpkg copy -b ${var.tanzu_registry_hostname}/tanzu-cluster-essentials/cluster-essentials-bundle:${var.tap_version} --to-repo ${var.tap_acr_name}.azurecr.io/tanzu-cluster-essentials/cluster-essentials-bundle --include-non-distributable-layers",
      "imgpkg copy -b ${var.tanzu_registry_hostname}/tanzu-application-platform/tap-packages:${var.tap_version} --to-repo ${var.tap_acr_name}.azurecr.io/tanzu-application-platform/tap-packages --include-non-distributable-layers",             
      "cd",
    ]
  }


  # Cluster essentials
  provisioner "remote-exec" {
    inline = [
      "pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='${var.tap_version}' --glob='tanzu-cluster-essentials-linux-amd64-*'",
      "mkdir tanzu-cluster-essentials",
      "tar xzvf tanzu-cluster-essentials-*-amd64-*.tgz -C tanzu-cluster-essentials",
      "export INSTALL_BUNDLE=${var.tap_acr_name}.azurecr.io/tanzu-cluster-essentials/cluster-essentials-bundle:${var.tap_version}",
      "export INSTALL_REGISTRY_HOSTNAME=${var.tap_acr_name}.azurecr.io",
      "export INSTALL_REGISTRY_USERNAME=${var.tap_acr_name}",
      "export INSTALL_REGISTRY_PASSWORD=${local.acr_pass}",
      "cd tanzu-cluster-essentials",           
      "az aks get-credentials --resource-group ${var.tap_full_aks_name} --name ${var.tap_full_aks_name} --admin --overwrite-existing",      
      "kubectl config get-contexts",
      "kubectl config use-context ${var.tap_full_aks_name}-admin",
      "kubectl create ns tap-install",    
      "./install.sh --yes",
      "tanzu secret registry add tap-registry --username \"${var.tap_acr_name}\" --password \"${local.acr_pass}\" --server ${var.tap_acr_name}.azurecr.io --export-to-all-namespaces --yes --namespace tap-install",
      "tanzu package repository add tanzu-tap-repository --url ${var.tap_acr_name}.azurecr.io/tanzu-application-platform/tap-packages:${var.tap_version} --namespace tap-install",   
    ]
  }

  # # Install full profile
  provisioner "remote-exec" { 
    inline = [
      "cd",
      "mkdir -p overlays",         
      "kubectl config use-context ${var.tap_full_aks_name}-admin",
      "export ACR_NAME=${var.tap_acr_name}",
      "export ACR_PASS=${local.acr_pass}",
      "export ACR_SERVER=$ACR_NAME.azure.io",
      "export ENVOY_IP=${azurerm_public_ip.tap-full-pip.ip_address}",
      "export DOMAIN_NAME=${var.tap_full_dns_prefix}.$(echo $ENVOY_IP | sed 's/\\./-/g').${var.domain_name}",
      "export TAP_RG=${azurerm_resource_group.tap_resource_group.name}",
      "cd",
      "chmod 755 create-contour-load-balancer.sh create-cnrs-default-tls.sh create-cnrs-slim.sh create-metadata-store-ingress-tls.sh create-tap-values.sh tap-install.sh",
      "./create-contour-load-balancer.sh; ./create-cnrs-default-tls.sh; ./create-cnrs-slim.sh; ./create-metadata-store-ingress-tls.sh; ./create-tap-values.sh",
      "kubectl -n tap-install create secret generic contour-loadbalancer-ip -o yaml --dry-run=client --from-file=overlays/contour-loadbalancer-ip.yaml | kubectl apply -f- ",      
      "kubectl -n tap-install create secret generic metadata-store-ingress-tls -o yaml --dry-run=client --from-file=overlays/metadata-store-ingress-tls.yaml  | kubectl apply -f- ",
      "kubectl -n tap-install create secret generic cnrs-default-tls -o yaml --dry-run=client --from-file=overlays/cnrs-default-tls.yaml | kubectl apply -f- ",
      "kubectl -n tap-install create secret generic cnrs-slim -o yaml --dry-run=client --from-file=overlays/cnrs-slim.yaml | kubectl apply -f- ",
      "cat tap-values.yaml",    
      "cd",   
    ]
  }


  # TODO Cert creation
      #   "docker run --rm -v $PWD/certs:/certs hitch openssl req -new -nodes -out /certs/ca.csr -keyout /certs/ca.key -subj \"/CN=default-ca/O=TAP/C=AU\"",
      # "sudo chown $USER:$USER certs/*",
      # "chmod og-rwx certs/ca.key",
      # "docker run --rm -v $PWD/certs:/certs hitch openssl x509 -req -in /certs/ca.csr -days 3650 -extfile /etc/ssl/openssl.cnf -extensions v3_ca -signkey /certs/ca.key -out /certs/ca.crt",  
      # "cat certs/ca.crt | sed 's/^/    /g' > tls-cert-sed.txt",
      # "cat certs/ca.key | sed 's/^/    /g' > tls-key-sed.txt",  
      # "ls",

  # TODO "./tap-install.sh ${var.tap_version} tap-values.yaml",  

      # "chmod 755 tap-install.sh; ./tap-install.sh ${var.tap_version} tap-values.yaml",   
      # "kubectl get packageinstall -n tap-install",
      # "sed -i.bak \"s/CHANGEME/$(kubectl get secret -n metadata-store metadata-store-read-client -otemplate='{{.data.token | base64decode}}')/\" tap-values-view.yaml",
      # "tanzu package installed update -n tap-install tap -f tap-values-view.yaml --poll-timeout 20m",
      # "kubectl get httpproxy -A",   

}  

 