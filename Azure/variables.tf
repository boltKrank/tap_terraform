### Account variables

variable "subscription_id" {
  type = string
  sensitive = true
}

variable "subscription_name" {
  type = string
  sensitive = true
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  type = string
  sensitive = true
}

variable "client_secret" {
  type = string
  sensitive = true
}

### Other variables
variable "prefix" {
  description = "The prefix which should be used for all resources"
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