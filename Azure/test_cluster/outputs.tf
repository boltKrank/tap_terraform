output "bootstrap_public_ip_address" {
  value = azurerm_public_ip.bootstrap_pip.ip_address
}

output "tap-test-ip" {
  value = azurerm_public_ip.tap-test-pip.ip_address
}

