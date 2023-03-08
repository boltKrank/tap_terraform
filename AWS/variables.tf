variable "location" {
  description = "Instance location"
}

variable "access_key" {
  description = "Access key for AWS"
}

variable "secret_key" {
  description = "Secret key for AWS"
}

variable "token" {
  description = "Session token for AWS"
}

## Networking

variable "tap_vpc_cidr_block" {
  description = "CIDR block for TAP"
  default = "10.20.20.0/25"
}

variable "tap_subnet_private_cidr_block" {
  description = "Private CIDR block for TAP"
  default = "10.20.20.0/26"  
}

variable "tap_subnet_public_cidr_block" {
  description = "Public CIDR block for TAP"
  default = "10.20.20.64/26"  
}

## Bootstrap

variable "bootstrap_ami" {
  description = "AMI to use for Bootstrap VM"
  default = "ami-08f0bc76ca5236b20" # ap-southeast-2 Ubuntu 22.04
}

variable "boostrap_instance_type" {
  description = "The machine to run bootstrap on"
  default = "t2.micro"
}