# See [https://github.com/hashicorp/learn-terraform-provision-eks-cluster/blob/main/main.tf]

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
  region = var.region
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

#### K8S STUFF #########

# IAM settings: [https://cloudly.engineer/2022/amazon-eks-iam-roles-and-policies-with-terraform/aws/]

# View cluster

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "modify_cluster" {
  statement {
      sid = "ModifyaEKScluster"

      actions = [
        "eks:AccessKubernetesApi",
        "eks:Associate*",
        "eks:Create*",
        "eks:Delete*",
        "eks:DeregisterCluster",
        "eks:DescribeCluster",
        
        "eks:DescribeUpdate",
        "eks:List*",
        "eks:TagResource",
        "eks:UntagResource",
        "eks:Update*"
      ]

      resources = [
        "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/*",
      ]
    }
}

resource "aws_iam_role" "modify_cluster" {
  name               = "eks-cluster-example"
  assume_role_policy = data.aws_iam_policy_document.modify_cluster.json
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.modify_cluster.name
}

resource "aws_eks_cluster" "view_cluster" {
  name = "${var.view_cluster_name}"
  role_arn = aws_iam_role.modify_cluster.arn

  vpc_config {
    subnet_ids = [aws_subnet.tap_private_subnet.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy
  ]  
}

output "endpoint" {
  value = aws_eks_cluster.view_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.view_cluster.certificate_authority[0].data 
} 

#### END K8S STUFF #####

# Bootstrap VM

resource "aws_key_pair" "boostrap_vm_key" {
  key_name   = "bootstrap-key"
  public_key = "${file("keys/id_rsa.pub")}"
}

resource "aws_instance" "bootstrap" {
  depends_on = [
    aws_eks_cluster.view_cluster
  ]
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

  connection {
    host = self.public_ip
    type = "ssh"
    user = var.bootstrap_login_user
    private_key = "${file("keys/id_rsa")}"
  }

  # Install Docker
  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo groupadd docker",
      "sudo usermod -aG docker $USER",
      "echo 'END DOCKER INSTALL'",
    ]
  }

  # Install kubectl
  provisioner "remote-exec" {
    inline = [
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
    ]
  }

}

output "boot_pip" {
  value = aws_instance.bootstrap.public_ip
}