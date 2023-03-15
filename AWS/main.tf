provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  token = var.token
}

# data "aws_availability_zones" "available" {}

# locals {
#   cluster_name = "learnk8s"
# }


###################################K8S START####################################################

# module "k8s-vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "3.18.1"

#   name                 = "k8s-vpc"
#   cidr                 = "172.16.0.0/16"
#   azs                  = data.aws_availability_zones.available.names
#   private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
#   public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
#   enable_nat_gateway   = true
#   single_nat_gateway   = true
#   enable_dns_hostnames = true

#   public_subnet_tags = {
#     "kubernetes.io/cluster/${local.cluster_name}" = "shared"
#     "kubernetes.io/role/elb"                      = "1"
#   }

#   private_subnet_tags = {
#     "kubernetes.io/cluster/${local.cluster_name}" = "shared"
#     "kubernetes.io/role/internal-elb"             = "1"
#   }
# }

# output "public_subnets" {
#   value = module.vpc.public_subnets
# }

# output "private_subnets" {
#   value = module.vpc.private_subnets
# }

# output "public_subnets_0" {
#   value = module.vpc.public_subnets[0]
# }

# output "private_subnets_0" {
#   value = module.vpc.private_subnets[0]
# }

# data "aws_eks_cluster" "cluster" {
#   name = module.eks.cluster_id
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks.cluster_id
# }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "18.30.3"

#   cluster_name    = "${local.cluster_name}"
#   cluster_version = "1.24"
#   subnet_ids      = module.vpc.private_subnets

#   vpc_id = module.vpc.vpc_id

#   eks_managed_node_groups = {
#     first = {
#       desired_capacity = 1
#       max_capacity     = 10
#       min_capacity     = 1

#       instance_type = "m5.large"
#     }
#   }
# }

# module "eks-kubeconfig" {
#   source     = "hyperbadger/eks-kubeconfig/aws"
#   version    = "1.0.0"

#   depends_on = [module.eks]
#   cluster_id =  module.eks.cluster_id
#   }

# resource "local_file" "kubeconfig" {
#   content  = module.eks-kubeconfig.kubeconfig
#   filename = "kubeconfig_${local.cluster_name}"
# }

###################################K8S END####################################################

###################################VM START####################################################

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
  public_key = "${file("keys/id_rsa.pub")}"
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

###################################VM END####################################################