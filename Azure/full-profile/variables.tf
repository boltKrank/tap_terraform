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



### ACR

variable "tap_acr_name" {
  description = "Name of the ACR registry"
}

variable "tap_k8s_version" {
  description = "Version of kubernetes to use"
  default = "1.24"
}

### AKS full

variable "tap_full_resource_group" {
  description = "Azure resource group for full profile cluster"
  default = "tap-full"
}

variable "tap_full_vm_size" {
  description = "Azure vm size for TAP full"
  default = "standard_f4s_v2" 
}

variable "tap_full_autoscaling" {
  description = "Whether to enable autoscaling for the full cluster"
  default = true
}

variable "tap_full_node_count" {
  description = "Initial node count for full cluster"
  default = 3
}

variable "tap_full_min_node_count" {
  description = "Minimum node count for full cluster"
  default = 1
}

variable "tap_full_max_node_count" {
  description = "Maximum node count for full cluster"
  default = 5
}

variable "tap_full_aks_name" {
  description = "Name of the full AKS cluster"
  default = "tap-full"
}


variable "tap_full_dns_prefix" {
  description = "DNS prefix for TAP full"
  default = "full"
}


# Temp variable (to delete)
variable "acr_pass" {
  description = "Temp password for DEBUGGING ACR (values should not be saved)"
}