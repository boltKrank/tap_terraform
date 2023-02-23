# https://github.com/hashicorp/terraform-provider-azurerm

# Conditions: https://stackoverflow.com/questions/55555963/how-to-write-an-if-else-elsif-conditional-statement-in-terraform

provider "azurerm" {
  features {}


  subscription_id = var.subscription_id
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


# TODO: Seperate subnets and resource groups for clusters

# -------------------------------------- START K8S STUFF ---------------------------------------------------

# # # # Create ACR

resource "azurerm_container_registry" "tap_acr" {
  #count               = 0
  name                = var.tap_acr_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location
  sku                 = "Standard"
  admin_enabled       = true  
}

locals {
  acr_pass = nonsensitive(azurerm_container_registry.tap_acr.admin_password)
}


# # # # # Create AKS TODO: change code to "profile: full" or loop "view,build,run"

# If full == 1 && (view || build || run == 1) -> throw error

# TAP FULL START

# Tap build cluster boolean -> count = var.tap_view_cluster

resource "azurerm_resource_group" "tap_full_rg" {
  # count = var.tap_full_count
  name = "${var.tap_full_aks_name}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "tap_full_aks" {
  count               = var.tap_full_count
  name                = var.tap_full_aks_name
  resource_group_name = azurerm_resource_group.tap_full_rg.name
  location            = azurerm_resource_group.tap_full_rg.location    
  dns_prefix = var.tap_full_dns_prefix
  kubernetes_version = var.tap_k8s_version
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_f4s_v2"   # Standard_b4ms (4vcpu, 16Gb mem)
    node_count = "0" #var.tap_full_node_count
    enable_auto_scaling = true
    min_count = "0" #var.tap_full_node_count
    max_count = "5"
    vnet_subnet_id = azurerm_subnet.internal.id
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

# TAP FULL END

# TAP VIEW START

# Tap build cluster boolean -> count = var.tap_view_cluster

resource "azurerm_resource_group" "tap_view_rg" {
  # count = var.tap_view_count
  name = "${var.tap_view_aks_name}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "tap_view_aks" {
  count               = var.tap_view_count
  name                = var.tap_view_aks_name
  resource_group_name = azurerm_resource_group.tap_view_rg.name
  location            = azurerm_resource_group.tap_view_rg.location    
  dns_prefix = var.tap_view_dns_prefix
  kubernetes_version = var.tap_k8s_version
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_f4s_v2" 
    node_count = var.tap_view_node_count
    enable_auto_scaling = true
    min_count = var.tap_view_node_count
    max_count = 3
    vnet_subnet_id = azurerm_subnet.internal.id
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


# TAP VIEW END

# # TAP BUILD START

# Tap build cluster boolean -> count = var.tap_build_cluster

resource "azurerm_resource_group" "tap_build_rg" {
  # count = var.tap_build_count
  name = "${var.tap_build_aks_name}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "tap_build_aks" {
  count               = var.tap_build_count
  name                = var.tap_build_aks_name
  resource_group_name = azurerm_resource_group.tap_build_rg.name
  location            = azurerm_resource_group.tap_build_rg.location    
  dns_prefix = var.tap_build_dns_prefix
  kubernetes_version = var.tap_k8s_version
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_f4s_v2" 
    node_count = var.tap_build_node_count
    enable_auto_scaling = true
    min_count = var.tap_build_node_count
    max_count = 3
    vnet_subnet_id = azurerm_subnet.internal.id
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


# # TAP BUILD END

# # TAP RUN START

# Tap run cluster boolean -> count = var.tap_run_cluster

resource "azurerm_resource_group" "tap_run_rg" {
  # count = var.tap_run_count
  name = "${var.tap_run_aks_name}-rg"
  location = var.location  
}

resource "azurerm_kubernetes_cluster" "tap_run_aks" {
  count               = var.tap_run_count
  name                = var.tap_run_aks_name
  resource_group_name = azurerm_resource_group.tap_run_rg.name
  location            = azurerm_resource_group.tap_run_rg.location    
  dns_prefix = var.tap_run_dns_prefix
  kubernetes_version = var.tap_k8s_version
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_f4s_v2" 
    node_count = var.tap_run_node_count
    enable_auto_scaling = true
    min_count = var.tap_run_node_count
    max_count = 3
    vnet_subnet_id = azurerm_subnet.internal.id
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


# # TAP RUN  END

# -------------------------------------- END K8S STUFF  --------------------------------------------------



# -------------------------------------- START BOOTSTRAP BOX ---------------------------------------------

resource "azurerm_public_ip" "bootstrap_pip" {
  name                = "bootstrap-pip"
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location
  allocation_method   = "Static"
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
    azurerm_kubernetes_cluster.tap_view_aks,
    azurerm_kubernetes_cluster.tap_build_aks,
    azurerm_kubernetes_cluster.tap_run_aks,
    azurerm_kubernetes_cluster.tap_full_aks,
    azurerm_container_registry.tap_acr,
  ]
  
  name                            = "bootstrap-vm"
  resource_group_name             = azurerm_resource_group.tap_resource_group.name
  location                        = azurerm_resource_group.tap_resource_group.location
  size                            = "Standard_B2s"
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

  # # Run commands:
    # TEST: "nohup &",
  provisioner "remote-exec" { 

    inline = [
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
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo groupadd docker",
      "sudo usermod -aG docker $USER",
      "wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz",
      "sudo tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz",
      "export PATH=$PATH:/usr/local/go/bin",
      "git clone https://github.com/boltKrank/imgpkg.git",
      "cd $HOME/imgpkg",
      "$HOME/imgpkg/hack/build.sh",
      "sudo cp $HOME/imgpkg/imgpkg /usr/local/bin/imgpkg",      
      "docker login ${var.tap_acr_name}.azurecr.io -u ${var.tap_acr_name} -p ${local.acr_pass}",
      "docker login ${var.tanzu_registry_hostname} -u ${var.tanzu_registry_username} -p ${var.tanzu_registry_password}",
      "imgpkg copy -b ${var.tanzu_registry_hostname}/tanzu-cluster-essentials/cluster-essentials-bundle:${var.tap_version} --to-repo ${var.tap_acr_name}.azurecr.io/tanzu-cluster-essentials/cluster-essentials-bundle --include-non-distributable-layers",
      "imgpkg copy -b ${var.tanzu_registry_hostname}/tanzu-application-platform/tap-packages:${var.tap_version} --to-repo ${var.tap_acr_name}.azurecr.io/tanzu-application-platform/tap-packages --include-non-distributable-layers",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "az login --service-principal -u ${var.sp_client_id} -p ${var.sp_secret} --tenant ${var.sp_tenant_id}",
      "echo \"Assigning Network Contributor Roles to AKS clusters\"",
      "cd",
      "pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='${var.tap_version}' --glob='tanzu-cluster-essentials-linux-amd64-*'",
      "mkdir tanzu-cluster-essentials",
      "tar xzvf tanzu-cluster-essentials-*-amd64-*.tgz -C tanzu-cluster-essentials",
      "export INSTALL_BUNDLE=${var.tap_acr_name}.azurecr.io/tanzu-cluster-essentials/cluster-essentials-bundle:${var.tap_version}",
      "export INSTALL_REGISTRY_HOSTNAME=${var.tap_acr_name}.azurecr.io",
      "export INSTALL_REGISTRY_USERNAME=${var.tap_acr_name}",
      "export INSTALL_REGISTRY_PASSWORD=${local.acr_pass}",
      "cd tanzu-cluster-essentials",           
      "az aks get-credentials --resource-group ${var.tap_view_aks_name}-rg --name ${var.tap_view_aks_name} --admin --overwrite-existing",
      "az aks get-credentials --resource-group ${var.tap_build_aks_name}-rg --name ${var.tap_build_aks_name}  --admin --overwrite-existing",
      "az aks get-credentials --resource-group ${var.tap_run_aks_name}-rg --name ${var.tap_run_aks_name}  --admin --overwrite-existing",
      "kubectl config get-contexts",
    ]
  }
}

      # kubectl config use-context view
      # ./install.sh --yes
      # kubectl config use-context build
      # ./install.sh --yes
      # kubectl config use-context run
      # ./install.sh --yes

      #QUARENTINE:

      #  "az aks get-credentials --resource-group ${var.resource_group} --name ${var.tap_view_aks_name} --admin --overwrite-existing",
      # "./install.sh --yes",
      # "az aks get-credentials --resource-group ${var.resource_group} --name ${var.tap_build_aks_name}  --admin --overwrite-existing",
      # "./install.sh --yes",
      # "az aks get-credentials --resource-group ${var.resource_group} --name ${var.tap_run_aks_name}  --admin --overwrite-existing",
      # "./install.sh --yes",
  # "cd",
      # "rm -f tanzu-cluster-essentials-*-amd64-*.tgz",
      # "tanzu secret registry add tap-registry --username ${var.tap_acr_name} --password ${local.acr_pass} --server ${var.tap_acr_name}.azurecr.io --export-to-all-namespaces --yes --namespace tap-install",
      # "tanzu package repository add tanzu-tap-repository --url ${var.tap_acr_name}.azurecr.io/tanzu-application-platform/tap-packages:${var.tap_version} --namespace tap-install",



     
      # TEST AFTER:
      
      #mkdir -p certs
      # rm -f certs/*
      # docker run --rm -v ${PWD}/certs:/certs hitch openssl req -new -nodes -out /certs/ca.csr -keyout /certs/ca.key -subj "/CN=default-ca/O=TAP/C=JP"
      # chmod og-rwx ca.key
      # docker run --rm -v ${PWD}/certs:/certs hitch openssl x509 -req -in /certs/ca.csr -days 3650 -extfile /etc/ssl/openssl.cnf -extensions v3_ca -signkey /certs/ca.key -out /certs/ca.crt

      # Apply service account to build and run:
      # kubectl apply -f tap-gui/tap-gui-viewer-service-account-rbac.yaml --context tap-build-admin
      # kubectl apply -f tap-gui/tap-gui-viewer-service-account-rbac.yaml --context tap-run-admin

      # Add tokens to build and run:
      # kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' --context tap-build-admin > tap-gui/cluster-url-build
      # kubectl -n tap-gui get secret tap-gui-viewer --context tap-build-admin -otemplate='{{index .data "token" | base64decode}}' > tap-gui/cluster-token-build
      # kubectl -n tap-gui get secret tap-gui-viewer --context tap-build-admin -otemplate='{{index .data "ca.crt"}}'  > tap-gui/cluster-ca-build

      # kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' --context tap-run-admin > tap-gui/cluster-url-run
      # kubectl -n tap-gui get secret tap-gui-viewer --context tap-run-admin -otemplate='{{index .data "token" | base64decode}}' > tap-gui/cluster-token-run
      # kubectl -n tap-gui get secret tap-gui-viewer --context tap-run-admin -otemplate='{{index .data "ca.crt"}}'  > tap-gui/cluster-ca-run
      

      # TODO: Clean up GoLang binary and imgpkg repo

      #       "sudo rm -rf /usr/local/go",

      # 
          #  "cd",
      #  "export TANZU_CLI_NO_INIT=true",
      #  "mkdir $HOME/tanzu",
      #  "tar -xvf tanzu-framework-linux-amd64-v0.25.4.1.tar -C $HOME/tanzu",
      #  "cd $HOME/tanzu",
      #  "export VERSION=v0.25.4", # Change to variable
      #  "sudo install cli/core/$VERSION/tanzu-core-linux_amd64 /usr/local/bin/tanzu",
      #  "tanzu init",
      #  "tanzu version",
      #  "mkdir $HOME/tanzu-cluster-essentials",
      #  "tar -xvf tanzu-cluster-essentials-linux-amd64-1.4.0.tgz -C $HOME/tanzu-cluster-essentials",
      #  "export INSTALL_BUNDLE=${var.tanzu_registry_hostname}/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:5fd527dda8af0e4c25c427e5659559a2ff9b283f6655a335ae08357ff63b8e7f",

      #  "export TAP_VERSION=1.4.0",
      #  "cd $HOME/tanzu-cluster-essentials",
      #  "./install.sh --yes",
      # "kubectl create ns tap-install",

      # https://ik.am/entries/723



      # 
      # "ACR_REGISTRY_ID=$(az acr show --name ${var.tap_acr_name} --query id --output tsv)",
      # "SERVICE_PRINCIPAL_RO_NAME=tap-ro",
      # "SERVICE_PRINCIPAL_RO_PASSWORD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_RO_NAME --scopes $ACR_REGISTRY_ID --years 100 --role acrpull --query password --output tsv)",
      # "SERVICE_PRINCIPAL_RO_USERNAME=$(az ad sp list --display-name $SERVICE_PRINCIPAL_RO_NAME --query \"[].appId\" --output tsv)",
      # "docker login ${var.tap_acr_name}.azurecr.io -u $SERVICE_PRINCIPAL_RO_USERNAME -p $SERVICE_PRINCIPAL_RO_PASSWORD",
      # "SERVICE_PRINCIPAL_RW_NAME=tap-rw",
      # "SERVICE_PRINCIPAL_RW_PASSWORD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_RW_NAME --scopes $ACR_REGISTRY_ID --years 100 --role acrpush --query password --output tsv)",
      # "SERVICE_PRINCIPAL_RW_USERNAME=$(az ad sp list --display-name $SERVICE_PRINCIPAL_RW_NAME --query \"[].appId\" --output tsv)",
      # docker login ${ACR_NAME}.azurecr.io -u ${SERVICE_PRINCIPAL_RO_USERNAME} -p ${SERVICE_PRINCIPAL_RO_PASSWORD}
      # "docker login ${var.tap_acr_name}.azurecr.io -u $SERVICE_PRINCIPAL_RW_USERNAME -p $SERVICE_PRINCIPAL_RW_PASSWORD",

      # cat <<EOF > env.sh
      # export ACR_NAME=${ACR_NAME}
      # export SERVICE_PRINCIPAL_RO_NAME=${SERVICE_PRINCIPAL_RO_NAME}
      # export SERVICE_PRINCIPAL_RO_USERNAME=${SERVICE_PRINCIPAL_RO_USERNAME}
      # export SERVICE_PRINCIPAL_RO_PASSWORD=${SERVICE_PRINCIPAL_RO_PASSWORD}
      # export SERVICE_PRINCIPAL_RW_NAME=${SERVICE_PRINCIPAL_RW_NAME}
      # export SERVICE_PRINCIPAL_RW_USERNAME=${SERVICE_PRINCIPAL_RW_USERNAME}
      # export SERVICE_PRINCIPAL_RW_PASSWORD=${SERVICE_PRINCIPAL_RW_PASSWORD}
      # EOF


      # 
      # "az aks get-credentials --resource-group ${var.resource_group} --name ${var.tap_full_aks_name}",

  
  # Send files:
  # provisioner "file" {
  #   connection {
  #     type = "ssh"
  #     user = var.bootstrap_username
  #     password = var.bootstrap_password
  #     host = azurerm_public_ip.bootstrap_pip.ip_address
  #     agent    = false
  #     timeout  = "10m"
  #   }
  #   source = "${path.cwd}/../binaries/" 
  #   destination = "/home/${var.bootstrap_username}" 
  # }








# End bootstrap




      # 


      # "tanzu secret registry add tap-registry --username ${var.tanzu_registry_username} --password ${var.tanzu_registry_password} --server ${var.tanzu_registry_hostname} --export-to-all-namespaces --yes --namespace tap-install",
      # "cd",
      # "kubectl -n tap-install create secret generic contour-default-tls -o yaml --dry-run=client --from-file=contour-default-tls.yaml | kubectl apply -f-",
      # "kubectl -n tap-install create secret generic cnrs-https -o yaml --dry-run=client --from-file=cnrs-https.yaml | kubectl apply -f-",
      # "kubectl -n tap-install create secret generic metadata-store-read-only-client -o yaml --dry-run=client --from-file=metadata-store-read-only-client.yaml | kubectl apply -f-",



  #     "wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz",
  #     "sudo rm -rf /usr/local/go",
  #     "sudo tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz",
  #     "export PATH=$PATH:/usr/local/go/bin",
  #     "git clone https://github.com/boltKrank/imgpkg.git",
  #     "cd $HOME/imgpkg",
  #     "$HOME/imgpkg/hack/build.sh",
  #     "sudo cp imgpkg /usr/local/bin/imgpkg",
  #     "cd",
  #     "imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${var.tap_version} --to-tar tap_${var.tap_version}.tar --registry-username ${var.tanzu_registry_username} --registry-password ${var.tanzu_registry_password} --include-non-distributable-layers",
  #     "imgpkg copy --tar tap_${var.tap_version}.tar --to-repo ${var.tap_acr_name}.azurecr.io/tanzu-application-platform/tap-packages --registry-username ${var.tap_acr_name} --registry-password ${azurerm_container_registry.tap_acr.admin_password} --include-non-distributable-layers",
  #     "tanzu secret registry add tap-registry --username ${var.tap_acr_name} --password ${azurerm_container_registry.tap_acr.admin_password} --server ${var.tap_acr_name}.azurecr.io --export-to-all-namespaces --yes --namespace tap-install",
  #     
   #   "tanzu package repository add tanzu-tap-repository --url ${var.tanzu_registry_hostname}/tanzu-application-platform/tap-packages:1.4.0 --namespace tap-install", 
      # "tanzu package repository get tanzu-tap-repository  --namespace tap-install",
      # "tanzu package install tap -p tap.tanzu.vmware.com -v ${var.tap_version} --values-file tap-values-view.yaml -n tap-install",  # TODO: tap-values.yaml file
   


    # Carvel tools (Path accessible):
    # "sudo cp $HOME/tanzu-cluster-essentials/kapp /usr/local/bin/kapp",
    # "sudo cp $HOME/tanzu-cluster-essentials/imgpkg /usr/local/bin/imgpkg",

    # Full build dependencies:
    # tanzu package repository add tbs-full-deps-repository --url registry.tanzu.vmware.com/tanzu-application-platform/full-tbs-deps-package-repo:1.9.0 --namespace tap-install
    # tanzu package available list -n tap-install
    # tanzu package install full-tbs-deps -p full-tbs-deps.tanzu.vmware.com -v 1.9.0 -n tap-install

    # Bootstrap CLI context:
    # "echo "source $HOME/kube-ps1.sh" >> ~/.bashrc"
    # "echo "PS1='[\u@\h \W $(kube_ps1)]\$ '" >> ~/.bashrc"



# -------------------------------------- END BOOTSTRAP BOX ---------------------------------------------





# -------------------------------------- START DNS  ----------------------------------------------------
# -------------------------------------- END   DNS  ----------------------------------------------------



# -------------------------------------- COPY PACKAGES TO ACR---------------------------------------------

# docker login MY-REGISTRY

# docker login registry.tanzu.vmware.com


# -------------------------------------- END COPY PACKAGES TO ACR---------------------------------------------