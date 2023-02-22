# https://github.com/hashicorp/terraform-provider-azurerm

# Conditions: https://stackoverflow.com/questions/55555963/how-to-write-an-if-else-elsif-conditional-statement-in-terraform

provider "azurerm" {
  features {}


  subscription_id = var.subscription_id
  # tap_sp
  client_id       = var.sp_client_id
  client_secret   = var.sp_secret
  tenant_id       = var.sp_tenant_id

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
  count               = var.tap_acr_count
  name                = var.tap_acr_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location
  sku                 = "Standard"
  admin_enabled       = true
}

# https://gaunacode.com/azure-container-registry-and-aks-with-terraform

# Create service principal read-only for ACR --role acrpull



# az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_RW_NAME /
# --scopes $ACR_REGISTRY_ID --years 100 --role acrpush --query password --output tsv

# https://stackoverflow.com/questions/55851777/whats-the-equivalent-terraform-code-for-azure-ad-sp-create-for-rbac

resource "azuread_service_principal" "tap_acr_read_only" {
  application_id = azurerm_container_registry.tap_acr.id  
}

resource "azuread_service_principal_password" "tap_acr_read_only" {
  service_principal_id = "${azuread_service_principal.auth.id}"
  value                = "${random_string.password.result}"
  end_date_relative    = "100y"
}

resource "azurerm_role_assignment" "acrpull_role" {
  name                             = "tap-ro"
  scope                            = azurerm_container_registry.tap_acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azuread_service_principal.tap_acr_read_only.id
}

# Create service principal read-write for ACR --role acrpush

resource "azuread_service_principal" "tap_acr_read_write" {
  application_id = azurerm_container_registry.tap_acr.id  
}

resource "azuread_service_principal_password" "tap_acr_read_write" {
  service_principal_id = "${azuread_service_principal.auth.id}"
  value                = "${random_string.password.result}"
  end_date_relative    = "100y"
}

resource "azurerm_role_assignment" "acrpush_role" {
  name                             = "tap-rw"
  scope                            = azurerm_container_registry.tap_acr.id
  role_definition_name             = "AcrPush"
  principal_id                     = azuread_service_principal.tap_acr_read_write.id
}

# # # # # Create AKS TODO: change code to "profile: full" or loop "view,build,run"

# If full == 1 && (view || build || run == 1) -> throw error

# TAP FULL START

# Tap build cluster boolean -> count = var.tap_view_cluster

resource "azurerm_kubernetes_cluster" "tap_full_aks" {
  count               = var.tap_full_count
  name                = var.tap_full_aks_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location    
  dns_prefix = var.tap_full_dns_prefix
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_f4s_v2"   # Standard_b4ms (4vcpu, 16Gb mem)
    node_count = "4" # 3 ~ 5
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

resource "azurerm_kubernetes_cluster" "tap_view_aks" {
  count               = var.tap_view_count
  name                = var.tap_view_aks_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location    
  dns_prefix = var.tap_view_dns_prefix
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_f4s_v2" 
    node_count = "3" # 3 ~ 5
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

resource "azurerm_kubernetes_cluster" "tap_build_aks" {
  count               = var.tap_build_count
  name                = var.tap_build_aks_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location    
  dns_prefix = var.tap_build_dns_prefix
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_f4s_v2" 
    node_count = "3" # 3 ~ 5
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

resource "azurerm_kubernetes_cluster" "tap_run_aks" {
  count               = var.tap_run_count
  name                = var.tap_run_aks_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location    
  dns_prefix = var.tap_run_dns_prefix
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_f4s_v2" 
    node_count = "3" # 3 ~ 5
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

  # # Run commands:
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
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo groupadd docker",
      "sudo usermod -aG docker $USER",
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
	    "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
    ]

      # "az login --service-principal -u ${var.sp_client_id} -p ${var.sp_secret} --tenant ${var.sp_tenant_id} ",
      # "ACR_REGISTRY_ID=$(az acr show --name ${var.tap_acr_name} --query id --output tsv)",
      # "SERVICE_PRINCIPAL_RO_NAME=tap-ro",
      # "SERVICE_PRINCIPAL_RO_PASSWORD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_RO_NAME --scopes $ACR_REGISTRY_ID --years 100 --role acrpull --query password --output tsv)",
      # "SERVICE_PRINCIPAL_RO_USERNAME=$(az ad sp list --display-name $SERVICE_PRINCIPAL_RO_NAME --query \"[].appId\" --output tsv)",
      # "docker login ${var.tap_acr_name}.azurecr.io -u $SERVICE_PRINCIPAL_RO_USERNAME -p $SERVICE_PRINCIPAL_RO_PASSWORD",
      # "SERVICE_PRINCIPAL_RW_NAME=tap-rw",
      # "SERVICE_PRINCIPAL_RW_PASSWORD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_RW_NAME --scopes $ACR_REGISTRY_ID --years 100 --role acrpush --query password --output tsv)",
      # "SERVICE_PRINCIPAL_RW_USERNAME=$(az ad sp list --display-name $SERVICE_PRINCIPAL_RW_NAME --query \"[].appId\" --output tsv)",
      # "docker login ${var.tap_acr_name}.azurecr.io -u $SERVICE_PRINCIPAL_RW_USERNAME -p $SERVICE_PRINCIPAL_RW_PASSWORD",


      # 
      # "az aks get-credentials --resource-group ${var.resource_group} --name ${var.tap_full_aks_name}",

    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }

}  
  
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
      #  "export INSTALL_REGISTRY_HOSTNAME=${var.tanzu_registry_hostname}",
      #  "export INSTALL_REGISTRY_USERNAME=${var.tanzu_registry_username}",
      #  "export INSTALL_REGISTRY_PASSWORD=${var.tanzu_registry_password}",
      #  "export TAP_VERSION=1.4.0",
      #  "cd $HOME/tanzu-cluster-essentials",
      #  "./install.sh --yes",
      # "kubectl create ns tap-install",
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
  #     "docker login ${var.tap_acr_name}.azurecr.io -u ${var.tap_acr_name} -p ${azurerm_container_registry.tap_acr.admin_password}",
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