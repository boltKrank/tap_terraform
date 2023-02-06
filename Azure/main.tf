# https://github.com/hashicorp/terraform-provider-azurerm

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B2s"
  admin_username                  = var.bootstrap_username
  admin_password                  = var.bootstrap_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id,
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
      host = azurerm_public_ip.main.ip_address
      agent    = false
      timeout  = "10m"
    }
    source = "${path.cwd}/../binaries/" 
    destination = "/home/${var.bootstrap_username}" 
  }

  provisioner "remote-exec" {
    inline = [
      "cd",
      "export TANZU_CLI_NO_INIT=true",
      "mkdir $HOME/tanzu",
      "tar -xvf tanzu-framework-linux-amd64-v0.25.4.1.tar -C $HOME/tanzu",
      "cd $HOME/tanzu",
      "export VERSION=v0.25.4",
      "sudo install cli/core/$VERSION/tanzu-core-linux_amd64 /usr/local/bin/tanzu",
      "tanzu version",
      "mkdir $HOME/tanzu-cluster-essentials",
      "tar -xvf tanzu-cluster-essentials-linux-amd64-1.4.0.tgz -C $HOME/tanzu-cluster-essentials",
    ]

    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }
}

# Create ACR

# Create AKS


# After AKS:

    # inline = [
    #   "export INSTALL_BUNDLE=${var.tanzu_registry_hostname}/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:5fd527dda8af0e4c25c427e5659559a2ff9b283f6655a335ae08357ff63b8e7f",
    #   "export INSTALL_REGISTRY_HOSTNAME=${var.tanzu_registry_hostname}",
    #   "export INSTALL_REGISTRY_USERNAME=${var.tanzu_registry_username}",
    #   "export INSTALL_REGISTRY_PASSWORD=${var.tanzu_registry_password}",
    #   "cd $HOME/tanzu-cluster-essentials",
    #   "./install.sh --yes",
    #   ]