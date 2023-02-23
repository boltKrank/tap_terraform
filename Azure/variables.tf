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

variable "tap_version" {
  description = "The version of TAP to install"
}

variable "pivnet_version" {
  description = "The version of pivnet CLI to install"
}

variable "pivnet_api_token" {
  description = "API Token for Pivnet"
}

variable "tanzu_cli_version" {
  description = "Tanzu CLI version"
}



### ACR

variable "tap_acr_name" {
  description = "Name of the ACR registry"
}

variable "tap_k8s_version" {
  description = "Version of kubernetes to use"
}

### AKS Full

variable "tap_full_resource_group" {
  description = "Azure resource group for full profile cluster"
  default = "tap_full_rg"
}

variable "tap_full_count" {
  description = "Number of AKS instances to be made for this type"
  default = 0
}

variable "tap_full_node_count" {
  description = "Number of AKS instances to be made for this type"
  default = "3"
}

variable "tap_full_aks_name" {
  description = "Name of the View AKS cluster"
}

variable "tap_full_dns_prefix" {
  description = "DNS prefix for TAP view"
}

### AKS View

variable "tap_view_resource_group" {
  description = "Azure resource group for view profile cluster"
  default = "tap_view_rg"
}

variable "tap_view_count" {
  description = "Number of AKS instances to be made for this type"
  default = 0
}

variable "tap_view_node_count" {
  description = "Initial node count for view cluster"
  default = "1"
}

variable "tap_view_aks_name" {
  description = "Name of the View AKS cluster"
}


variable "tap_view_dns_prefix" {
  description = "DNS prefix for TAP view"
}


### AKS Build

variable "tap_build_resource_group" {
  description = "Azure resource group for build profile cluster"
  default = "tap_build_rg"
}

variable "tap_build_count" {
  description = "Number of AKS instances to be made for this type"
  default = 0
}

variable "tap_build_node_count" {
  description = "Initial node count for build cluster"
  default = "1"
}

variable "tap_build_aks_name" {
  description = "Name of the build AKS cluster"
}


variable "tap_build_dns_prefix" {
  description = "DNS prefix for TAP build"
}


### AKS Run

variable "tap_run_resource_group" {
  description = "Azure resource group for run profile cluster"
  default = "tap_build_run"
}

variable "tap_run_count" {
  description = "Number of AKS instances to be made for this type"
  default = 0
}
variable "tap_run_node_count" {
  description = "Initial node count for run cluster"
  default = "1"
}

variable "tap_run_aks_name" {
  description = "Name of the run AKS cluster"
}


variable "tap_run_dns_prefix" {
  description = "DNS prefix for TAP run"
}


