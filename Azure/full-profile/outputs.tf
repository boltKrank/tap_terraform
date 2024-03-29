output "bootstrap_public_ip_address" {
  value = azurerm_public_ip.bootstrap_pip.ip_address
}

output "aks_envoy_ip" {
  value = azurerm_public_ip.tap-full-pip.ip_address
}

# output "tls_private_key" {
#   value     = tls_private_key.example_ssh.private_key_pem
#   sensitive = true
# }