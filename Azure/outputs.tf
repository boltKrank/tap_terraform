output "resource_group_name" {
  value = azurerm_resource_group.tap_resource_group.name
}

output "outgoing_full_ip" {
  value = data.azurerm_public_ip.tap_full_PIP.ip_address
}

# output "outgoing_view_ip" {
#   value = data.azurerm_public_ip.tap_view_PIP.ip_address
# }

# output "outgoing_build_ip" {
#   value = data.azurerm_public_ip.tap_build_PIP.ip_address
# }

# output "outgoing_run_ip" {
#   value = data.azurerm_public_ip.tap_run_PIP.ip_address
# }

output "public_ip_address" {
  value = azurerm_public_ip.bootstrap_pip.ip_address
}

# output "tls_private_key" {
#   value     = tls_private_key.example_ssh.private_key_pem
#   sensitive = true
# }