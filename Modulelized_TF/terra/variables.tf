variable "region" { default = "ap-northeast-2" } # 사용할 Region 
variable "vpc_cidr" { default = "10.10.0.0/16" } # VPC CIDR
variable "public_subnet1_cidr" { default = "10.10.1.0/24" } # Public Subnet 1 CIDR
variable "public_subnet2_cidr" { default = "10.10.2.0/24" } # Public Subnet 2 CIDR
variable "private_subnet1_cidr" { default = "10.10.11.0/24" } # Private Subnet 1 CIDR
variable "private_subnet2_cidr" { default = "10.10.12.0/24" } # Private Subnet 2 CIDR
variable "hosted_zone_id" { default = "Z076855811XMR50K5FM98" } # Route53 호스티드 존 ID
variable "cluster_name" { default = "my-default-cluster" } # EKS 클러스터 이름
variable "cluster_role_name" { default = "YourEKSClusterRole" } # EKS 클러스터 Role 이름
variable "cluster_policies" { # EKS 클러스터에 연결할 Policies
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy",
  ]
}
variable "node_group_name" { default = "YourEKSNodeGroups" } # EKS Node Group 이름
variable "node_role_name" { default = "YourEKSNodeRole" } # EKS Node Role 이름
variable "node_policies" { # EKS 노드에 연결할 Policies
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",          # MinimalPolicy 대신 사용
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # PullOnly 대신 사용
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"                # 누락된 필수 정책 추가
  ]
}

variable "kubernetes_version" { 
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"  # 최신 안정 버전으로 수정
}
variable "key_pair_name" { description = "Existing SSH key pair name" }
variable "public_access_cidrs" {
  description = "EKS 공개 API 엔드포인트 접근 허용 CIDR 목록"
  type        = list(string)
  # 보안상 권장: 본인 공인IP/32만 허용. (임시로 0.0.0.0/0 사용 가능)
  default = ["0.0.0.0/0"]
}

# -------------------------------------------------------------------------------------------------
# Bastion configuration variables
# -------------------------------------------------------------------------------------------------

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.large"
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to access the bastion via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# -------------------------------------------------------------------------------------------------
# RDS configuration variables
# -------------------------------------------------------------------------------------------------

variable "db_name" {
  description = "Name of the MySQL database to create on RDS"
  type        = string
  default     = "shopdb"
}

variable "db_master_username" {
  description = "Master username for the RDS database"
  type        = string
  default     = "admin"
}

variable "db_master_password" {
  description = "Master user password for the RDS database"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for the RDS instance"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Version of the MySQL engine to use for RDS"
  type        = string
  default     = "8.0"
}

# -------------------------------------------------------------------------------------------------
# ElastiCache (Redis) configuration variables
# -------------------------------------------------------------------------------------------------

variable "redis_node_type" {
  description = "Node type for the Redis cluster"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  description = "Version of the Redis engine to use"
  type        = string
  default     = "7.0"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes in the Redis cluster"
  type        = number
  default     = 1
}
