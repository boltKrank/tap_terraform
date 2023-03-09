### Account variables

variable "subscription_id" {
  type = string
  # sensitive = true
}

variable "subscription_name" {
  type = string
  # sensitive = true
}

### Service Principal

variable "sp_tenant_id" {
  type = string
}

variable "sp_client_id" {
  type = string
  # sensitive = true
}

variable "sp_secret" {
  type = string
  # sensitive = true
}

### Other variables
variable "resource_group" {
  description = "Resource group name"
  default = "tap-rg"
}

variable "location" {
  description = "The Azure Region in which all resources should be created."
}

variable "domain_name" {
  description = "Domain name use for accessing."
  default = "sslip.io"
}

### Bootstrap box

variable "bootstrap_username" {
  description = "Password for bootsrap box"
}

variable "bootstrap_password" {
  description = "Password for bootsrap box"
}

variable "bootstrap_vm_size" {
  description = "Password for bootsrap box"
  default = "Standard_B2s"
}

variable "tanzu_registry_hostname" {
  description = "URL for Tanzu registry"
  default = "registry.tanzu.vmware.com"
}


variable "tanzu_registry_username" {
  description = "Username for Tanzu registry"
  default = "tanzu_registry_username"
}


variable "tanzu_registry_password" {
  description = "Password for Tanzu registry"
}

variable "tap_version" {
  description = "The version of TAP to install"
  default = "1.4.0"
}

variable "tbs_version" {
  description = "The version of Tanzu Build Service to install"
  default = "1.9.0"
}

variable "pivnet_version" {
  description = "The version of pivnet CLI to install"
  default = "3.0.1"
}

variable "pivnet_api_token" {
  description = "API Token for Pivnet"
}

variable "tanzu_cli_version" {
  description = "Tanzu CLI version"
  default = "0.25.4"
}

