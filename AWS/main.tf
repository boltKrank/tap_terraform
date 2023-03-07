# AWS TAP Install
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.location
  access_key = var.access_key
  secret_key = var.secret_key
  token = var.token
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "tap-vpc"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"  

  tags = {
    Name = "tap-subnet"
  }
}

resource "aws_network_interface" "bootstrap_nic" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

# Securtiy groups

resource "aws_instance" "bootstrap" {
  ami           = "ami-08f0bc76ca5236b20" # ap-southeast-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.bootstrap_nic.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}