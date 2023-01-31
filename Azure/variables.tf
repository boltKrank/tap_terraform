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

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}