# TAP Multi-cluster deployment

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

locals {
  acr_pass = "IidZRIfCirvXQAYr9PwBl1Hrfs34zWcGaG8jn/OaTx+ACRBrOCwE"
}

# -------------------------------------- START K8S STUFF ---------------------------------------------------

# # # # Create ACR

# resource "azurerm_container_registry" "tap_acr" {
#   count               = 0
#   name                = var.tap_acr_name
#   resource_group_name = azurerm_resource_group.tap_resource_group.name
#   location            = azurerm_resource_group.tap_resource_group.location
#   sku                 = "Standard"
#   admin_enabled       = true  
# }


# TAP VIEW START

resource "azurerm_resource_group" "tap_view_rg" {  
  name = var.tap_view_resource_group
  location = var.location
}

resource "azurerm_public_ip" "tap-view-pip" {
    
  name                = "envoy-ip" 
  resource_group_name = var.tap_view_aks_name
  location            = azurerm_resource_group.tap_view_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
} 

resource "azurerm_kubernetes_cluster" "tap_view_aks" {
  depends_on = [
    azurerm_public_ip.tap-view-pip,
  ]  
  name                = var.tap_view_aks_name
  resource_group_name = azurerm_resource_group.tap_view_rg.name
  location            = azurerm_resource_group.tap_view_rg.location    
  dns_prefix          = var.tap_view_dns_prefix
  kubernetes_version  = var.tap_k8s_version
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = var.tap_view_vm_size
    node_count = var.tap_view_node_count    
    enable_auto_scaling = var.tap_view_autoscaling
    min_count = var.tap_view_min_node_count
    max_count = var.tap_view_max_node_count
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

resource "azurerm_resource_group" "tap_build_rg" {  
  name = var.tap_build_resource_group
  location = var.location
}

resource "azurerm_kubernetes_cluster" "tap_build_aks" {  
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
    vm_size    = var.tap_build_vm_size    
    node_count = var.tap_build_node_count
    enable_auto_scaling = var.tap_build_autoscaling
    min_count = var.tap_build_min_node_count
    max_count = var.tap_vuild_max_node_count
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

resource "azurerm_resource_group" "tap_run_rg" {  
  name = var.tap_run_resource_group
  location = var.location  
}

resource "azurerm_public_ip" "tap-run-pip" {
    
  name                = "envoy-ip" 
  resource_group_name = var.tap_run_resource_group
  location            = azurerm_resource_group.tap_run_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
} 

resource "azurerm_kubernetes_cluster" "tap_run_aks" {  
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
    vm_size    = var.tap_run_vm_size
    node_count = var.tap_run_node_count
    enable_auto_scaling = var.tap_run_autoscaling
    min_count = var.tap_run_min_node_count
    max_count = var.tap_run_max_node_count
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
    azurerm_kubernetes_cluster.tap_view_aks,
    azurerm_kubernetes_cluster.tap_build_aks,
    azurerm_kubernetes_cluster.tap_run_aks,      
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
      "pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='${var.tap_version}' --glob='tanzu-cluster-essentials-linux-amd64-*'",
      "mkdir tanzu-cluster-essentials",
      "tar xzvf tanzu-cluster-essentials-*-amd64-*.tgz -C tanzu-cluster-essentials",
      "export INSTALL_BUNDLE=${var.tap_acr_name}.azurecr.io/tanzu-cluster-essentials/cluster-essentials-bundle:${var.tap_version}",
      "export INSTALL_REGISTRY_HOSTNAME=${var.tap_acr_name}.azurecr.io",
      "export INSTALL_REGISTRY_USERNAME=${var.tap_acr_name}",
      "export INSTALL_REGISTRY_PASSWORD=${local.acr_pass}",
      "cd tanzu-cluster-essentials",           
      "az aks get-credentials --resource-group ${var.tap_view_aks_name} --name ${var.tap_view_aks_name} --admin --overwrite-existing",
      "az aks get-credentials --resource-group ${var.tap_build_aks_name} --name ${var.tap_build_aks_name}  --admin --overwrite-existing",
      "az aks get-credentials --resource-group ${var.tap_run_aks_name} --name ${var.tap_run_aks_name}  --admin --overwrite-existing",
      "kubectl config get-contexts",
      "kubectl config use-context ${var.tap_view_aks_name}-admin",
      "./install.sh --yes",
      "kubectl config use-context ${var.tap_build_aks_name}-admin",
      "./install.sh --yes",
      "kubectl config use-context ${var.tap_run_aks_name}-admin",
      "./install.sh --yes", 
      "cd",
      "rm -f tanzu-cluster-essentials-*-amd64-*.tgz",    
    ]     
  }

  # # Certs and view cluster
  provisioner "remote-exec" { 
    inline = [
      "mkdir -p certs",
      "rm -f certs/*",
      "docker run --rm -v $PWD/certs:/certs hitch openssl req -new -nodes -out /certs/ca.csr -keyout /certs/ca.key -subj \"/CN=default-ca/O=TAP/C=AU\"",
      "sudo chown $USER:$USER certs/*",
      "chmod og-rwx certs/ca.key",
      "docker run --rm -v $PWD/certs:/certs hitch openssl x509 -req -in /certs/ca.csr -days 3650 -extfile /etc/ssl/openssl.cnf -extensions v3_ca -signkey /certs/ca.key -out /certs/ca.crt",            
      "kubectl apply -f tap-gui/tap-gui-viewer-service-account-rbac.yaml --context ${var.tap_build_aks_name}-admin",
      "kubectl apply -f tap-gui/tap-gui-viewer-service-account-rbac.yaml --context ${var.tap_run_aks_name}-admin",
      "kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' --context ${var.tap_build_aks_name}-admin > $HOME/tap-gui/cluster-url-build",
      "kubectl -n tap-gui get secret tap-gui-viewer --context ${var.tap_build_aks_name}-admin -otemplate='{{index .data \"token\" | base64decode}}' > $HOME/tap-gui/cluster-token-build",
      "kubectl -n tap-gui get secret tap-gui-viewer --context ${var.tap_build_aks_name}-admin -otemplate='{{index .data \"ca.crt\"}}'  > $HOME/tap-gui/cluster-ca-build",
      "kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' --context ${var.tap_run_aks_name}-admin > $HOME/tap-gui/cluster-url-run",
      "kubectl -n tap-gui get secret tap-gui-viewer --context ${var.tap_run_aks_name}-admin -otemplate='{{index .data \"token\" | base64decode}}' > $HOME/tap-gui/cluster-token-run",
      "kubectl -n tap-gui get secret tap-gui-viewer --context ${var.tap_run_aks_name}-admin -otemplate='{{index .data \"ca.crt\"}}'  > $HOME/tap-gui/cluster-ca-run",
      "kubectl config use-context ${var.tap_view_aks_name}-admin",
      "kubectl create ns tap-install",
      "tanzu secret registry add tap-registry --username \"${var.tap_acr_name}\" --password \"${local.acr_pass}\" --server ${var.tap_acr_name}.azurecr.io --export-to-all-namespaces --yes --namespace tap-install",
      "tanzu package repository add tanzu-tap-repository --url ${var.tap_acr_name}.azurecr.io/tanzu-application-platform/tap-packages:${var.tap_version} --namespace tap-install",      
      "export ENVOY_IP_VIEW=${azurerm_public_ip.tap-view-pip.ip_address}",
      "export DOMAIN_NAME_VIEW=${var.tap_view_dns_prefix}.$(echo $ENVOY_IP_VIEW | sed 's/\\./-/g').${var.domain_name}",
      "echo $DOMAIN_NAME_VIEW",
      "echo tap-gui.$DOMAIN_NAME_VIEW > url.txt",
      "cd",
      "mkdir -p overlays/view",
      "cd",
      "cat certs/ca.crt | sed 's/^/    /g' > tls-cert-sed.txt",
      "cat certs/ca.key | sed 's/^/    /g' > tls-key-sed.txt",
      "chmod 755 create-contour-default-tls.sh; ./create-contour-default-tls.sh",
      "cat overlays/view/contour-default-tls.yaml",
      "chmod 755 create-tap-gui-db.sh; ./create-tap-gui-db.sh",
      "chmod 755 create-metadata-store-client.sh; ./create-metadata-store-client.sh",
      "cd",
      "kubectl -n tap-install create secret generic contour-default-tls -o yaml --dry-run=client --from-file=overlays/view/contour-default-tls.yaml  | kubectl apply -f-",
      "kubectl -n tap-install create secret generic tap-gui-db -o yaml --dry-run=client --from-file=overlays/view/tap-gui-db.yaml | kubectl apply -f- ",
      "kubectl -n tap-install create secret generic metadata-store-read-only-client -o yaml --dry-run=client   --from-file=overlays/view/metadata-store-read-only-client.yaml | kubectl apply -f- ",
      "chmod 755 create-tap-values-view.sh; ./create-tap-values-view.sh",
      "cat tap-values-view.yaml",
      "cd",  
      "chmod 755 tap-install.sh; ./tap-install.sh ${var.tap_version} tap-values-view.yaml",   
      "kubectl get packageinstall -n tap-install",
      "sed -i.bak \"s/CHANGEME/$(kubectl get secret -n metadata-store metadata-store-read-client -otemplate='{{.data.token | base64decode}}')/\" tap-values-view.yaml",
      "tanzu package installed update -n tap-install tap -f tap-values-view.yaml --poll-timeout 20m",
      "kubectl get httpproxy -A",
      "echo 'END VIEW CLUSTER'",      
    ]
  }

  # # Build cluster
  provisioner "remote-exec" { 
    inline = [
      "kubectl config use-context tap-build-admin",
      "kubectl create ns tap-install",
      "tanzu secret registry add tap-registry --username \"${var.tap_acr_name}\" --password \"${local.acr_pass}\" --server ${var.tap_acr_name}.azurecr.io --export-to-all-namespaces --yes --namespace tap-install",
      "tanzu package repository add tanzu-tap-repository --url ${var.tap_acr_name}.azurecr.io/tanzu-application-platform/tap-packages:${var.tap_version} --namespace tap-install",   
      "tanzu package repository add tbs-full-deps-repository --url ${var.tap_acr_name}.azurecr.io/tanzu-cluster-essentials/full-tbs-deps-package-repo:${var.tbs_version} --namespace tap-install",
      "cd",
      "chmod +x create-repository-secret.sh",
      "./create-repository-secret.sh ${var.tap_acr_name}.azurecr.io ${var.tap_acr_name} ${local.acr_pass}",
      "cd",
      "chmod 755 create-metadata-store-secrets-build.sh; ./create-metadata-store-secrets-build.sh",
      "kubectl -n tap-install create secret generic metadata-store-secrets -o yaml --dry-run=client --from-file=overlays/build/metadata-store-secrets.yaml | kubectl apply -f-",
      "cd",
      "export ACR_NAME=${var.tap_acr_name}",
      "chmod 755 create-tap-values-build.sh; ./create-tap-values-build.sh",
      "cd",
      "./tap-install.sh ${var.tap_version} tap-values-build.yaml",
      "tanzu package install full-tbs-deps -p full-tbs-deps.tanzu.vmware.com -v ${var.tbs_version} -n tap-install --poll-timeout 30m",
      "tanzu package installed list -n tap-install ",
      "kubectl get clusterbuilder",      
      "echo 'END BUILD CLUSTER'",
    ]
  }

  #   #Run cluster
    provisioner "remote-exec" { 
      inline = [
      "kubectl config use-context tap-run-admin",
      "kubectl create ns tap-install",
      "tanzu secret registry add tap-registry --username \"${var.tap_acr_name}\" --password \"${local.acr_pass}\" --server ${var.tap_acr_name}.azurecr.io --export-to-all-namespaces --yes --namespace tap-install",
      "tanzu package repository add tanzu-tap-repository --url ${var.tap_acr_name}.azurecr.io/tanzu-application-platform/tap-packages:${var.tap_version} --namespace tap-install",  
      "export ENVOY_IP_RUN=${azurerm_public_ip.tap-run-pip.ip_address}",
      "az network public-ip list -o table",
      "export DOMAIN_NAME_RUN=${var.tap_run_dns_prefix}.$(echo $ENVOY_IP_RUN | sed 's/\\./-/g').${var.domain_name}",
      "echo $DOMAIN_NAME_RUN",
      "cd",
      "mkdir -p overlays/run",
      "cp overlays/view/contour-default-tls.yaml  overlays/run/contour-default-tls.yaml",
      "kubectl -n tap-install create secret generic contour-default-tls -o yaml --dry-run=client --from-file=overlays/view/contour-default-tls.yaml  | kubectl apply -f-",
      "chmod 755 create-cnrs-https.sh; ./create-cnrs-https.sh",
      "kubectl -n tap-install create secret generic cnrs-https -o yaml --dry-run=client --from-file=overlays/run/cnrs-https.yaml  | kubectl apply -f-",
      "chmod 755 create-tap-values-run.sh; ./create-tap-values-run.sh",
      "cat tap-values-run.yaml",
      "./tap-install.sh ${var.tap_version} tap-values-run.yaml",
      "tanzu package installed list -n tap-install",
      "tanzu secret registry add tbs-registry-credentials --server ${var.tap_acr_name}.azurecr.io --username \"${var.tap_acr_name}\" --password \"${local.acr_pass}\"  --export-to-all-namespaces --yes --namespace tap-install",
      "kubectl create namespace demo",
      "kubectl label namespaces demo apps.tanzu.vmware.com/tap-ns=",
      "kubectl get secrets,serviceaccount,rolebinding,pods,workload,configmap -n demo",           
      "echo 'END RUN CLUSTER'",
      "cat url.txt",
      ]
    }  

    # Create supply-chains, workload and deployment
    provisioner "remote-exec" {
      inline = [
        "kubectl config use-context tap-build-admin",
        "NAMESPACE=demo",
        "kubectl create ns ${NAMESPACE}",
        "kubectl label namespaces demo apps.tanzu.vmware.com/tap-ns=",
        "tanzu secret registry add tbs-registry-credentials --server ${var.tap_acr_name}.azurecr.io --username \"${var.tap_acr_name}\" --password \"${local.acr_pass}\"  --export-to-all-namespaces --yes --namespace tap-install",
        "cd",
        "chmod 755 create-maven-pipeline.sh; ./create-maven-pipeline.sh",
        "chmod 755 create-scan-policy.sh; ./create-scan-policy.sh",
        "chmod 755 install-grype.sh; ./install-grype.sh",
        "tanzu package install -n tap-install grype-${NAMESPACE} -p grype.scanning.apps.tanzu.vmware.com -v ${var.tap_version} -f grype-${NAMESPACE}-values.yaml",
        "tanzu apps workload apply tanzu-java-web-app --app tanzu-java-web-app --git-repo https://github.com/making/tanzu-java-web-app --git-branch main --type web --label apps.tanzu.vmware.com/has-tests=true --annotation autoscaling.knative.dev/minScale=1 --request-memory 768Mi -n demo -y",
        "tanzu apps workload get -n demo tanzu-java-web-app",
        "kubectl get cm -n ${NAMESPACE} tanzu-java-web-app-deliverable -otemplate='{{.data.deliverable}}' > deliverable.yaml",
        "kubectl config use-context tap-run-admin",
        "kubectl apply -f deliverable.yaml -n ${NAMESPACE}",
        "echo TODO:",
        "kubectl get ksvc -n demo tanzu-java-web-app",
        "curl -k $(kubectl get ksvc -n demo tanzu-java-web-app -ojsonpath='{.status.url}')",
      ]

      # Need to add:
      # kubectl patch deliverable tanzu-java-web-app -n ${NAMESPACE} --type merge --patch "{\"metadata\":{\"labels\":{\"carto.run/workload-name\":\"tanzu-java-web-app\",\"carto.run/workload-namespace\":\"${NAMESPACE}\"}}}"

    }      
    
  }

      # Removed

      # NEED TO RE-ADD:


      # OLD_IMGPKG (Fixes AKS issue):
      # "wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz",
      # "sudo tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz",
      # "export PATH=$PATH:/usr/local/go/bin",
      # "git clone https://github.com/boltKrank/imgpkg.git",
      # "cd $HOME/imgpkg",
      # "$HOME/imgpkg/hack/build.sh",
      # "sudo cp $HOME/imgpkg/imgpkg /usr/local/bin/imgpkg",      
      

      # ORIGINAL:
      # "imgpkg copy -b ${var.tanzu_registry_hostname}/tanzu-cluster-essentials/cluster-essentials-bundle:${var.tap_version} --to-repo ${var.tap_acr_name}.azurecr.io/tanzu-cluster-essentials/cluster-essentials-bundle --include-non-distributable-layers",
      # "imgpkg copy -b ${var.tanzu_registry_hostname}/tanzu-application-platform/tap-packages:${var.tap_version} --to-repo ${var.tap_acr_name}.azurecr.io/tanzu-application-platform/tap-packages --include-non-distributable-layers",
      

 