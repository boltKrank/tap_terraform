output "resource_group_name" {
  value = azurerm_resource_group.tap_resource_group.name
}

output "cluster_egress_ip" {
  value = data.azurerm_public_ip.tapclusterPIP.ip_address
}

output "cluster_fqdn" {
  value = data.azurerm_public_ip.tapclusterPIP.fqdn
}

output "public_ip_address" {
  value = azurerm_public_ip.bootstrap_pip.ip_address
}

# output "tls_private_key" {
#   value     = tls_private_key.example_ssh.private_key_pem
#   sensitive = true
# }