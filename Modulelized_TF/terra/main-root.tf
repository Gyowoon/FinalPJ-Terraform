terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# AWS 를 Provider로 지정 
provider "aws" {  
  region = var.region
}

# Terraform 실행 시 연결된 AWS 계정 정보 조회 (aws sts get-caller-identity)
data "aws_caller_identity" "current" {}

# Bastion AMI 조회
data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ----------------------------- EKS Cluster Provider -----------------------------
# EKS Cluster가 생성된 후, 해당 Cluster에 접근하기 위한 Kubernetes Provider 설정
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}
# EKS Cluster 인증 토큰 생성 
# EKS Cluster에 접근하기 위한 인증 토큰을 생성하는 데이터 소스
data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  token                  = data.aws_eks_cluster_auth.eks.token
}
# ----------------------------- Main Infrastructure -----------------------------

module "vpc" {
  source = "./modules/VPC"

  vpc_cidr            = var.vpc_cidr
  public_subnet1_cidr = var.public_subnet1_cidr
  public_subnet2_cidr = var.public_subnet2_cidr
  private_subnet1_cidr = var.private_subnet1_cidr
  private_subnet2_cidr = var.private_subnet2_cidr
  region              = var.region
  environment         = "dev"
  cluster_name        = var.cluster_name
}

# -----------------------------------------------------------------------------
# EKS Cluster Module
# -----------------------------------------------------------------------------

module "eks" {
  source = "./modules/EKS"

  cluster_name           = var.cluster_name
  kubernetes_version    = var.kubernetes_version
  cluster_role_name     = var.cluster_role_name
  node_role_name        = var.node_role_name
  node_group_name       = var.node_group_name
  cluster_policies      = var.cluster_policies
  node_policies         = var.node_policies
  subnet_ids            = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  public_access_cidrs   = var.public_access_cidrs
  key_pair_name         = var.key_pair_name
  account_id            = data.aws_caller_identity.current.account_id
  region                = var.region
  shopping_mall_namespace = "shop"
}


# ---------------------------------------------------------------------------
# Bastion Host Module
# ---------------------------------------------------------------------------
module "bastion" {
  source = "./modules/BASTION"

  cluster_name                   = var.cluster_name
  vpc_id                        = module.vpc.vpc_id
  subnet_id                     = module.vpc.public_subnet_ids[0]
  key_pair_name                = var.key_pair_name
  bastion_instance_type        = var.bastion_instance_type
  bastion_allowed_cidrs        = var.bastion_allowed_cidrs
  region                       = var.region
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
  account_id                   = data.aws_caller_identity.current.account_id
  cluster_endpoint             = module.eks.cluster_endpoint
  cluster_ca_certificate       = module.eks.cluster_certificate_authority
}


# Add Bastion role to aws-auth ConfigMap for cluster admin access
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = module.bastion.bastion_role_arn
        username = "bastion-admin"
        groups   = ["system:masters"]
      }
    ])
  }

  force = true

  depends_on = [module.eks]
}

## SG자동 추가 Revised [08/31,수정] END ##

# ---------------------------------------------------------------------------
# MySQL RDS Module
# The following resources create a MySQL RDS instance in the private
# subnets.  A dedicated security group restricts inbound connections to
# within the VPC CIDR block, and a subnet group ensures the instance is
# placed into the private subnets.  The master credentials and DB name are
# supplied via variables.  Final snapshots are skipped on deletion for
# simplicity in development environments.
# ---------------------------------------------------------------------------
module "rds" {
  source = "./modules/RDS"

  cluster_name         = var.cluster_name
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = module.vpc.vpc_cidr
  subnet_ids          = module.vpc.private_subnet_ids
  db_instance_class   = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine_version   = var.db_engine_version
  db_master_username  = var.db_master_username
  db_master_password  = var.db_master_password
  db_name             = var.db_name
}

# RDS resources are now managed by the RDS module

# ---------------------------------------------------------------------------
# ElastiCache (Redis) Module
# ---------------------------------------------------------------------------
module "redis" {
  source = "./modules/REDIS"

  cluster_name          = var.cluster_name
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr
  subnet_ids           = module.vpc.private_subnet_ids
  redis_node_type      = var.redis_node_type
  redis_num_cache_nodes = var.redis_num_cache_nodes
  redis_engine_version = var.redis_engine_version
  redis_port           = 6379
}

# ---------------------------------------------------------------------------
# ExternalDNS Module
# ---------------------------------------------------------------------------
module "dns" {
  source = "./modules/DNS"

  cluster_name   = var.cluster_name
  hosted_zone_id = var.hosted_zone_id
  account_id     = data.aws_caller_identity.current.account_id
  eks_cluster_id = module.eks.cluster_id

  depends_on = [module.eks]
}