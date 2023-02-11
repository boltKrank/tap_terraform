# https://github.com/hashicorp/terraform-provider-azurerm

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tap_resource_group" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.tap_resource_group.location
  resource_group_name = azurerm_resource_group.tap_resource_group.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.tap_resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}


# -------------------------------------- START K8S STUFF ---------------------------------------------------

# Create ACR

resource "azurerm_container_registry" "acr" {
  name                = var.tap_acr_name
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location
  sku                 = "Standard"
}

# # Create AKS

resource "azurerm_kubernetes_cluster" "tap_aks" {
  name                = "tapcluster" #TODO
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location    
  dns_prefix = "tap"
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_B4ms"  # Standard_b4ms (4vcpu, 16Gb mem)
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

data "azurerm_public_ip" "tapclusterPIP" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.tap_aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.tap_aks.node_resource_group
}


# -------------------------------------- END K8S STUFF  --------------------------------------------------



# -------------------------------------- START BOOTSTRAP BOX ---------------------------------------------

# resource "azurerm_public_ip" "bootstrap_pip" {
#   name                = "${var.prefix}-bootstrap-pip"
#   resource_group_name = azurerm_resource_group.tap_resource_group.name
#   location            = azurerm_resource_group.tap_resource_group.location
#   allocation_method   = "Static"
# }

# resource "azurerm_network_interface" "bootstrap_nic" {
#   name                = "${var.prefix}-nic"
#   resource_group_name = azurerm_resource_group.tap_resource_group.name
#   location            = azurerm_resource_group.tap_resource_group.location

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.internal.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.bootstrap_pip.id
#   }
# }

# resource "azurerm_linux_virtual_machine" "main" {
#   name                            = "${var.prefix}-vm"
#   resource_group_name             = azurerm_resource_group.tap_resource_group.name
#   location                        = azurerm_resource_group.tap_resource_group.location
#   size                            = "Standard_B2s"
#   admin_username                  = var.bootstrap_username
#   admin_password                  = var.bootstrap_password
#   disable_password_authentication = false
#   network_interface_ids = [
#     azurerm_network_interface.bootstrap_nic.id,
#   ]

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-focal"
#     sku       = "20_04-lts-gen2"
#     version   = "latest"
#   }

#   os_disk {
#     storage_account_type = "Standard_LRS"
#     caching              = "ReadWrite"
#   }
#   provisioner "file" {
#     connection {
#       type = "ssh"
#       user = var.bootstrap_username
#       password = var.bootstrap_password
#       host = azurerm_public_ip.main.ip_address
#       agent    = false
#       timeout  = "10m"
#     }
#     source = "${path.cwd}/../binaries/" 
#     destination = "/home/${var.bootstrap_username}" 
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "cd",
#       "export TANZU_CLI_NO_INIT=true",
#       "mkdir $HOME/tanzu",
#       "tar -xvf tanzu-framework-linux-amd64-v0.25.4.1.tar -C $HOME/tanzu",
#       "cd $HOME/tanzu",
#       "export VERSION=v0.25.4",
#       "sudo install cli/core/$VERSION/tanzu-core-linux_amd64 /usr/local/bin/tanzu",
#       "tanzu version",
#       "cd",
#       "mkdir $HOME/tanzu-cluster-essentials",
#       "tar -xvf tanzu-cluster-essentials-linux-amd64-1.4.0.tgz -C $HOME/tanzu-cluster-essentials",
#       "sudo cp $HOME/tanzu-cluster-essentials/kapp /usr/local/bin/kapp",
#       "sudo cp $HOME/tanzu-cluster-essentials/imgpkg /usr/local/bin/imgpkg",
#       "wget -O- https://carvel.dev/install.sh > install.sh",
#       "sudo bash install.sh",
#       "curl -fsSL https://get.docker.com -o get-docker.sh",
#       "sudo sh get-docker.sh",
#       "sudo groupadd docker",
#       "sudo usermod -aG docker $USER",

#       # "curl -L https://aka.ms/InstallAzureCli | bash",
#     ]

#     connection {
#       host     = self.public_ip_address
#       user     = self.admin_username
#       password = self.admin_password
#     }
#   }
# }


# -------------------------------------- END BOOTSTRAP BOX ---------------------------------------------




# After AKS:

    # inline = [
    #   "export INSTALL_BUNDLE=${var.tanzu_registry_hostname}/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:5fd527dda8af0e4c25c427e5659559a2ff9b283f6655a335ae08357ff63b8e7f",
    #   "export INSTALL_REGISTRY_HOSTNAME=${var.tanzu_registry_hostname}",
    #   "export INSTALL_REGISTRY_USERNAME=${var.tanzu_registry_username}",
    #   "export INSTALL_REGISTRY_PASSWORD=${var.tanzu_registry_password}",
    #   "cd $HOME/tanzu-cluster-essentials",
    #   "./install.sh --yes",
    #   ]