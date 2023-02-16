# https://github.com/hashicorp/terraform-provider-azurerm

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
}

# # # # # Create AKS TODO: change code to "profile: full" or loop "view,build,run"

# TAP VIEW START

resource "azurerm_kubernetes_cluster" "tap_view_aks" {
  name                = var.tap_view_aks_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location    
  dns_prefix = var.tap_view_dns_prefix
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

data "azurerm_public_ip" "tap_view_PIP" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.tap_view_aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.tap_view_aks.node_resource_group
}

# TAP VIEW END

# # TAP BUILD START

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
    source = "${path.cwd}/tap-values/" 
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
    source = "${path.cwd}/../Common/kube-ps1.sh" 
    destination = "/home/${var.bootstrap_username}/kube-ps1.sh" 
  }

  # remote-exec provisioner array [iterate,view,build,run] - branch after Tanzu CLI

  # x1 (full) x3/4 (multi)

  provisioner "remote-exec" { 
    inline = [
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
	    "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo groupadd docker",
      "sudo usermod -aG docker $USER",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "az login --service-principal -u ${var.sp_client_id} -p ${var.sp_secret} --tenant ${var.sp_tenant_id} ",
      # view/build/run "az aks get-credentials --resource-group ${var.resource_group} --name ${var.tap_aks_name}",
      "cd",
      "export TANZU_CLI_NO_INIT=true",
      "mkdir $HOME/tanzu",
      "tar -xvf tanzu-framework-linux-amd64-v0.25.4.1.tar -C $HOME/tanzu",
      "cd $HOME/tanzu",
      "export VERSION=v0.25.4", # Change to variable
      "sudo install cli/core/$VERSION/tanzu-core-linux_amd64 /usr/local/bin/tanzu",
      "tanzu init",
      "tanzu version",
      "cd",
      "mkdir $HOME/tanzu-cluster-essentials",
      "tar -xvf tanzu-cluster-essentials-linux-amd64-1.4.0.tgz -C $HOME/tanzu-cluster-essentials",
      "export INSTALL_BUNDLE=${var.tanzu_registry_hostname}/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:5fd527dda8af0e4c25c427e5659559a2ff9b283f6655a335ae08357ff63b8e7f",
      "export INSTALL_REGISTRY_HOSTNAME=${var.tanzu_registry_hostname}",
      "export INSTALL_REGISTRY_USERNAME=${var.tanzu_registry_username}",
      "export INSTALL_REGISTRY_PASSWORD=${var.tanzu_registry_password}",
      "cd $HOME/tanzu-cluster-essentials",
      "./install.sh --yes",
      "kubectl create ns tap-install",
      "tanzu secret registry add tap-registry --username ${var.tanzu_registry_username} --password ${var.tanzu_registry_password} --server ${var.tanzu_registry_hostname} --export-to-all-namespaces --yes --namespace tap-install",
      "tanzu package repository add tanzu-tap-repository --url ${var.tanzu_registry_hostname}/tanzu-application-platform/tap-packages:1.4.0 --namespace tap-install", # Change TAP version to variable
      "tanzu package repository get tanzu-tap-repository --namespace tap-install",
      # "tanzu package install tap -p tap.tanzu.vmware.com -v 1.4.0 --values-file tap-values-view.yaml -n tap-install",  # TODO: tap-values.yaml file
    ]

    # Full build dependencies:
    # tanzu package repository add tbs-full-deps-repository --url registry.tanzu.vmware.com/tanzu-application-platform/full-tbs-deps-package-repo:1.9.0 --namespace tap-install
    # tanzu package available list -n tap-install
    # tanzu package install full-tbs-deps -p full-tbs-deps.tanzu.vmware.com -v 1.9.0 -n tap-install

    # "echo "source $HOME/kube-ps1.sh" >> ~/.bashrc"
    # "echo "PS1='[\u@\h \W $(kube_ps1)]\$ '" >> ~/.bashrc"

    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }
}


# -------------------------------------- END BOOTSTRAP BOX ---------------------------------------------





# -------------------------------------- START DNS  ----------------------------------------------------
# -------------------------------------- END   DNS  ----------------------------------------------------



# -------------------------------------- COPY PACKAGES TO ACR---------------------------------------------

# docker login MY-REGISTRY

# docker login registry.tanzu.vmware.com


# -------------------------------------- END COPY PACKAGES TO ACR---------------------------------------------