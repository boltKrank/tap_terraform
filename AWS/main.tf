# See [https://github.com/hashicorp/learn-terraform-provision-eks-cluster/blob/main/main.tf]
provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  token = var.token
}

data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

locals {
  cluster_name = "learnk8s"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "eks-kubeconfig" {
  source     = "hyperbadger/eks-kubeconfig/aws"
  version    = "1.0.0"

  depends_on = [module.eks]
  cluster_id =  module.eks.cluster_id
  }

resource "local_file" "kubeconfig" {
  content  = module.eks-kubeconfig.kubeconfig
  filename = "kubeconfig_${local.cluster_name}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name                 = "k8s-vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.30.3"

  cluster_name    = "${local.cluster_name}"
  cluster_version = "1.24"
  subnet_ids      = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  eks_managed_node_groups = {
    first = {
      desired_capacity = 1
      max_capacity     = 10
      min_capacity     = 1

      instance_type = "m5.large"
    }
  }
}

## Create VM ##




########################## Bootstrap ######################################################

# Gateways
resource "aws_internet_gateway" "tap_igw" {
  vpc_id = module.vpc.vpc_id
  tags = {
    "Name" = "TAP-gateway"
  }  
}

# TODO: Make securtiy groups stricter
resource "aws_security_group" "all_open" {
  name = "all_open_sg"
  description = "all ports open"
  vpc_id = module.vpc.vpc_id

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
  subnet_id = module.vpc.public_subnets[0]
  private_ip = "172.16.4.0"
  security_groups = [aws_security_group.all_open.id]
  tags = {
    "Name" = "Bootstrap-nic"
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
  depends_on = [
    module.eks-kubeconfig
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
  
  # Test JSON generation
  # provisioner "file" {
  #   destination = "~/build-service-trust-policy.json"
  #   content = jsonencode({
  #         "Version": "2012-10-17",
  #         "Statement": [
  #           {
  #             "Effect": "Allow",
  #             "Principal": {
  #               "Federated": "arn:aws:iam::${var.access_key}:oidc-provider/${var.view_cluster_name}"
  #             },
  #             "Action": "sts:AssumeRoleWithWebIdentity",
  #             "Condition": {
  #               "StringEquals": {
  #                   "${var.view_cluster_name}:aud": "sts.amazonaws.com"
  #               },
  #               "StringLike": {
  #                   "${var.view_cluster_name}:sub": [
  #                       "system:serviceaccount:kpack:controller",
  #                       "system:serviceaccount:build-service:dependency-updater-controller-serviceaccount"
  #                   ]
  #               }
  #           }
  #       }
  #   ]
  #   })
  # }

  # Install Docker
  # provisioner "remote-exec" {
  #   inline = [
  #     "curl -fsSL https://get.docker.com -o get-docker.sh",
  #     "sudo sh get-docker.sh",
  #     "sudo groupadd docker",
  #     "sudo usermod -aG docker $USER",
  #     "echo 'END DOCKER INSTALL'",
  #   ]
  # }

  # Install kubectl
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

########################## Bootstrap End ######################################################