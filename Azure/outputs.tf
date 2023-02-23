output "resource_group_name" {
  value = azurerm_resource_group.tap_resource_group.name
}

output "bootstrap_public_ip_address" {
  value = azurerm_public_ip.bootstrap_pip.ip_address
}

output "acr_pwd" {
  value = nonsensitive(azurerm_container_registry.tap_acr.admin_password)
}

# output "tls_private_key" {
#   value     = tls_private_key.example_ssh.private_key_pem
#   sensitive = true
# }