output "resource_group_name" {
  value = azurerm_resource_group.tap_resource_group.name
}

output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
}

# output "tls_private_key" {
#   value     = tls_private_key.example_ssh.private_key_pem
#   sensitive = true
# }