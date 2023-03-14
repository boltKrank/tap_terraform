provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  token = var.token
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "learnk8s"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name                 = "k8s-vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24","172.16.4.0/24"]
  public_subnets       = ["172.16.5.0/24", "172.16.6.0/24", "172.16.7.0/24","172.16.8.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets_0" {
  value = module.vpc.public_subnets[0]
}

output "private_subnets_0" {
  value = module.vpc.private_subnets[0]
}



###################################K8S START####################################################

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

resource "aws_network_interface" "bootstrap_nic" {
  subnet_id   = module.vpc.public_subnets[0]
  private_ip = "172.16.5.1"

  tags = {
    Name = "primary_network_interface"
  }
}

# # Public IP
resource "aws_eip" "bootstrap_pip" {  
  vpc      = true
  network_interface = aws_network_interface.bootstrap_nic.id  
  tags = {
    "Name" = "Bootstrap-pip"
  }  
}

resource "aws_key_pair" "boostrap_vm_key" {
  key_name   = "bootstrap-key"
  public_key = "${file("keys/id_rsa.pub")}"
}

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

  connection {
    host = self.public_ip
    type = "ssh"
    user = var.bootstrap_login_user
    private_key = "${file("keys/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "cd",
      "KUBECONFIG=./kubeconfig_learnk8s",
      "kubectl get pods --all-namespaces",
    ]
  }

}


  output "boot_pip" {
    value = aws_instance.bootstrap.public_ip
  }


###################################VM END####################################################