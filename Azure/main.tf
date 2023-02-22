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
  name                = var.tap_acr_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location
  sku                 = "Standard"
  admin_enabled       = true
}

# # # # # Create AKS TODO: change code to "profile: full" or loop "view,build,run"

# If full == 1 && (view || build || run == 1) -> throw error

# TAP FULL START

# Tap build cluster boolean -> count = var.tap_view_cluster

resource "azurerm_kubernetes_cluster" "tap_full_aks" {
  name                = var.tap_full_aks_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location    
  dns_prefix = var.tap_full_dns_prefix
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_B4ms"  # Standard_b4ms (4vcpu, 16Gb mem)
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

data "azurerm_public_ip" "tap_full_PIP" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.tap_full_aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.tap_full_aks.node_resource_group
}

# TAP FULL END

# TAP VIEW START

# Tap build cluster boolean -> count = var.tap_view_cluster

# resource "azurerm_kubernetes_cluster" "tap_view_aks" {
#   name                = var.tap_view_aks_name
#   resource_group_name = azurerm_resource_group.tap_resource_group.name
#   location            = azurerm_resource_group.tap_resource_group.location    
#   dns_prefix = var.tap_view_dns_prefix
#   tags                = {
#     Environment = "Development"
#   }

#   default_node_pool {
#     name       = "agentpool"
#     vm_size    = "Standard_B4ms"  # Standard_b4ms (4vcpu, 16Gb mem)
#     node_count = "3" # 3 ~ 5
#     vnet_subnet_id = azurerm_subnet.internal.id
#   }

#   service_principal {
#     client_id = var.sp_client_id
#     client_secret = var.sp_secret
#   }

#   network_profile {
#     network_plugin    = "kubenet"
#     load_balancer_sku = "standard"
#   }

# }

# data "azurerm_public_ip" "tap_view_PIP" {
#   name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.tap_view_aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
#   resource_group_name = azurerm_kubernetes_cluster.tap_view_aks.node_resource_group
# }

# TAP VIEW END

# # TAP BUILD START

# Tap build cluster boolean -> count = var.tap_build_cluster

# resource "azurerm_kubernetes_cluster" "tap_build_aks" {
#   name                = var.tap_build_aks_name
#   resource_group_name = azurerm_resource_group.tap_resource_group.name
#   location            = azurerm_resource_group.tap_resource_group.location    
#   dns_prefix = var.tap_build_dns_prefix
#   tags                = {
#     Environment = "Development"
#   }

#   default_node_pool {
#     name       = "agentpool"
#     vm_size    = "Standard_B4ms"  # Standard_b4ms (4vcpu, 16Gb mem)
#     node_count = "3" # 3 ~ 5
#     vnet_subnet_id = azurerm_subnet.internal.id
#   }

#   service_principal {
#     client_id = var.sp_client_id
#     client_secret = var.sp_secret
#   }

#   network_profile {
#     network_plugin    = "kubenet"
#     load_balancer_sku = "standard"
#   }

# }

# data "azurerm_public_ip" "tap_build_PIP" {
#   name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.tap_build_aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
#   resource_group_name = azurerm_kubernetes_cluster.tap_build_aks.node_resource_group
# }

# # TAP BUILD END

# # TAP RUN START

# Tap run cluster boolean -> count = var.tap_run_cluster

# resource "azurerm_kubernetes_cluster" "tap_run_aks" {
#   name                = var.tap_run_aks_name
#   resource_group_name = azurerm_resource_group.tap_resource_group.name
#   location            = azurerm_resource_group.tap_resource_group.location    
#   dns_prefix = var.tap_run_dns_prefix
#   tags                = {
#     Environment = "Development"
#   }

#   default_node_pool {
#     name       = "agentpool"
#     vm_size    = "Standard_B4ms"  # Standard_b4ms (4vcpu, 16Gb mem)
#     node_count = "3" # 3 ~ 5
#     vnet_subnet_id = azurerm_subnet.internal.id
#   }

#   service_principal {
#     client_id = var.sp_client_id
#     client_secret = var.sp_secret
#   }

#   network_profile {
#     network_plugin    = "kubenet"
#     load_balancer_sku = "standard"
#   }

# }

# data "azurerm_public_ip" "tap_run_PIP" {
#   name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.tap_run_aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
#   resource_group_name = azurerm_kubernetes_cluster.tap_run_aks.node_resource_group
# }

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
  
  provisioner "file" {
    connection {
      type = "ssh"
      user = var.bootstrap_username
      password = var.bootstrap_password
      host = azurerm_public_ip.bootstrap_pip.ip_address
      agent    = false
      timeout  = "10m"
    }
    source = "${path.cwd}/../binaries/" 
    destination = "/home/${var.bootstrap_username}" 
  }

  provisioner "file" {
    connection {
      type = "ssh"
      user = var.bootstrap_username
      password = var.bootstrap_password
      host = azurerm_public_ip.bootstrap_pip.ip_address
      agent    = false
      timeout  = "10m"
    }
    source = "${path.cwd}/../Common/" 
    destination = "/home/${var.bootstrap_username}/" 
  }

  provisioner "file" {
    connection {
      type = "ssh"
      user = var.bootstrap_username
      password = var.bootstrap_password
      host = azurerm_public_ip.bootstrap_pip.ip_address
      agent    = false
      timeout  = "10m"
    }
    source = "${path.cwd}/../Common/kube-ps1.sh" 
    destination = "/home/${var.bootstrap_username}/kube-ps1.sh" 
  }

  # remote-exec provisioner array [iterate,view,build,run] - branch after Tanzu CLI

  # x1 (full) x3/4 (multi)

  # Install kubectl and docker and Azure CLI

  provisioner "remote-exec" { 
    inline = [
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
	    "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo groupadd docker",
      "sudo usermod -aG docker $USER",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
    ]

    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }

  # Currently only view cluster
  # Need a branch for full/multi  
  


  # # Azure CLI install for bootstrap, install on single default AKS cluster
  provisioner "remote-exec" { 
    inline = [
      "az login --service-principal -u ${var.sp_client_id} -p ${var.sp_secret} --tenant ${var.sp_tenant_id} ",
      "az aks get-credentials --resource-group ${var.resource_group} --name ${var.tap_view_aks_name}",
    ]
    
    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }

  # Tanzu CLI install
  provisioner "remote-exec" { 
    inline = [
       "cd",
       "export TANZU_CLI_NO_INIT=true",
       "mkdir $HOME/tanzu",
       "tar -xvf tanzu-framework-linux-amd64-v0.25.4.1.tar -C $HOME/tanzu",
       "cd $HOME/tanzu",
       "export VERSION=v0.25.4", # Change to variable
       "sudo install cli/core/$VERSION/tanzu-core-linux_amd64 /usr/local/bin/tanzu",
       "tanzu init",
       "tanzu version",
    ]

    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }

  # # Cluster essentials (Rotate for multi-cluster)
  provisioner "remote-exec" { 
    inline = [
       "mkdir $HOME/tanzu-cluster-essentials",
       "tar -xvf tanzu-cluster-essentials-linux-amd64-1.4.0.tgz -C $HOME/tanzu-cluster-essentials",
       "export INSTALL_BUNDLE=${var.tanzu_registry_hostname}/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:5fd527dda8af0e4c25c427e5659559a2ff9b283f6655a335ae08357ff63b8e7f",
       "export INSTALL_REGISTRY_HOSTNAME=${var.tanzu_registry_hostname}",
       "export INSTALL_REGISTRY_USERNAME=${var.tanzu_registry_username}",
       "export INSTALL_REGISTRY_PASSWORD=${var.tanzu_registry_password}",
       "export TAP_VERSION=1.4.0",
       "cd $HOME/tanzu-cluster-essentials",
       "./install.sh --yes",
    ]

    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }


  # # TAP install (rotate for multi-cluster)
  provisioner "remote-exec" { 
    inline = [
      "kubectl create ns tap-install",
      "tanzu secret registry add tap-registry --username ${var.tanzu_registry_username} --password ${var.tanzu_registry_password} --server ${var.tanzu_registry_hostname} --export-to-all-namespaces --yes --namespace tap-install",
      "cd",
    ]

    # "tanzu package install tap -p tap.tanzu.vmware.com -v ${var.tap_version} --values-file tap-values-full.yaml -n tap-install",  # TODO: tap-values.yaml file

    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }



}  # End bootstrap






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