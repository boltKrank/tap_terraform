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
resource "aws_vpc" "tap_vpc" {
  cidr_block = var.tap_vpc_cidr_block

  tags = {
    Name = "tap-vpc"
  }
}

# Create subnets (public and private)
resource "aws_subnet" "tap_private_subnet" {
  vpc_id            = aws_vpc.tap_vpc.id
  cidr_block        = var.tap_subnet_private_cidr_block

  tags = {
    Name = "tap-private-subnet"
  }
}

resource "aws_subnet" "tap_public_subnet" {
  vpc_id            = aws_vpc.tap_vpc.id
  cidr_block        = var.tap_subnet_public_cidr_block
  tags = {
    Name = "tap-public-subnet"
  }
}

# Route table + associations

resource "aws_route_table" "tap_rt" {
  vpc_id = aws_vpc.tap_vpc.id
  tags = {
    "Name" = "TAP-Route-table"
  }  
}

resource "aws_route_table_association" "tap_public" {
  subnet_id = aws_subnet.tap_public_subnet.id
  route_table_id = aws_route_table.tap_rt.id
}

resource "aws_route_table_association" "tap_private" {
  subnet_id = aws_subnet.tap_private_subnet.id
  route_table_id = aws_route_table.tap_rt.id
}

# Gateways
resource "aws_internet_gateway" "tap_igw" {
  vpc_id = aws_vpc.tap_vpc.id
  tags = {
    "Name" = "TAP-gateway"
  }  
}

resource "aws_route" "internet_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.tap_rt.id
  gateway_id = aws_internet_gateway.tap_igw.id  
}

# TODO: Make securtiy groups stricter
resource "aws_security_group" "all_open" {
  name = "all_open_sg"
  description = "all ports open"
  vpc_id = aws_vpc.tap_vpc.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All allowed in"
    from_port = "0"   
    to_port = "0"
    protocol = "-1"    
  } 

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All allowed out"
    from_port = "0"   
    to_port = "0"
    protocol = "-1"    
  } 

  tags = {
    "Name" = "All-open-sg"
  }  
}

# NICs
resource "aws_network_interface" "bootstrap_nic" {
  subnet_id = aws_subnet.tap_public_subnet.id
  private_ips = ["10.20.20.120"] 
  security_groups = [aws_security_group.all_open.id]
  tags = {
    Name = "Bootstrap-nic"
  }
}

# Public IP
resource "aws_eip" "bootstrap_pip" {  
  vpc      = true
  network_interface = aws_network_interface.bootstrap_nic.id
  tags = {
    "Name" = "Bootstrap-pip"
  }  
}


# Bootstrap VM

resource "aws_key_pair" "boostrap_vm_key" {
  key_name   = "bootstrap-key"
  public_key = var.bootstrap_vm_public_key
}

resource "aws_instance" "bootstrap" {
  ami           = var.bootstrap_ami
  instance_type = var.boostrap_instance_type
  key_name = "bootstrap-key"

  network_interface {
    network_interface_id = aws_network_interface.bootstrap_nic.id
    device_index         = 0
  }
  tags = {
    "Name" = "tap-bootstrap-vm"
  }
}

output "boot_pip" {
  value = aws_instance.bootstrap.public_ip
}