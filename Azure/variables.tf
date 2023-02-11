### Account variables

variable "subscription_id" {
  type = string
  sensitive = true
}

variable "subscription_name" {
  type = string
  sensitive = true
}

### Service Principal

variable "sp_tenant_id" {
  type = string
}

variable "sp_client_id" {
  type = string
  sensitive = true
}

variable "sp_secret" {
  type = string
  sensitive = true
}

### Other variables
variable "resource_group" {
  description = "Resource group name"
}

variable "location" {
  description = "The Azure Region in which all resources should be created."
}

### Bootstrap box

variable "bootstrap_username" {
  description = "Password for bootsrap box"
}

variable "bootstrap_password" {
  description = "Password for bootsrap box"
}


variable "tanzu_registry_hostname" {
  description = "URL for Tanzu registry"
}


variable "tanzu_registry_username" {
  description = "Username for Tanzu registry"
}


variable "tanzu_registry_password" {
  description = "Password for Tanzu registry"
}

### ACR

variable "tap_acr_name" {
  description = "Name of the ACR registry"
}

### AKS

variable "tap_aks_name" {
  description = "Name of the AKS cluster"
}


variable "tap_dns_prefix" {
  description = "DNS prefix for TAP"
}


