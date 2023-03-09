# Single cluster + bootstrap for testing


provider "azurerm" {
  features {}

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

# TEST CLUSTER


resource "azurerm_public_ip" "tap-test-pip" {
    
  name                = "envoy-ip" 
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
} 

resource "azurerm_kubernetes_cluster" "tap_test_aks" {
  depends_on = [
    azurerm_public_ip.tap-test-pip,
  ]  
  name                = "tap-test"
  resource_group_name = azurerm_resource_group.tap_resource_group.name
  location            = azurerm_resource_group.tap_resource_group.location    
  dns_prefix          = "test"
  kubernetes_version  = "1.24"
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_f4s_v2" 
    node_count = "3"  
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

# TAP TEST END


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
    azurerm_kubernetes_cluster.tap_test_aks,     
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
      "docker login ${var.tanzu_registry_hostname} -u ${var.tanzu_registry_username} -p ${var.tanzu_registry_password}",               
      "cd",
      "pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='${var.tap_version}' --glob='tanzu-cluster-essentials-linux-amd64-*'",
      "mkdir tanzu-cluster-essentials",
      "tar xzvf tanzu-cluster-essentials-*-amd64-*.tgz -C tanzu-cluster-essentials",      
      "export INSTALL_REGISTRY_HOSTNAME=${var.tanzu_registry_hostname}",
      "export INSTALL_REGISTRY_USERNAME=${var.tanzu_registry_username}",
      "export INSTALL_REGISTRY_PASSWORD=${var.tanzu_registry_password}",
      "cd tanzu-cluster-essentials",           
      "az aks get-credentials --resource-group test --name test--admin --overwrite-existing",
      "kubectl config get-contexts",
      "kubectl config use-context test-admin",
      "./install.sh --yes",
      "cd",
      "rm -f tanzu-cluster-essentials-*-amd64-*.tgz",    
    ]     
  } 
    
}
