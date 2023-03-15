variable "region" {
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

variable "bootstrap_private_subnet" {
  default = "172.16.1.0/24"
}

variable "bootstrap_public_subnet" {
  default = "172.16.5.0/24"
}

variable "view_cluster_private_subnet" {
  default = "172.16.2.0/24"
}

variable "view_cluster_public_subnet" {
  default = "172.16.6.0/24"
}

variable "build_cluster_private_subnet" {
  default = "172.16.3.0/24"
}

variable "build_cluster_public_subnet" {
  default = "172.16.7.0/24"
}

variable "run_cluster_private_subnet" {
  default = "172.16.4.0/24"
}

variable "run_cluster_public_subnet" {
  default = "172.16.8.0/24"
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

variable "bootstrap_login_user" {
  description = "The username to login to the bootstrap VM"
  default = "ubuntu"
}

### Clusters

variable "view_cluster_name" {
  description = "The name of the view cluster"
  default = "tap-view-cluster"
}
