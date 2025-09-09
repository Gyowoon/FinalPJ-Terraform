variable "cluster_name" {
  description = "Name of the EKS cluster for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Bastion will be created"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID where Bastion will be deployed"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the key pair for SSH access"
  type        = string
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
}

variable "bastion_allowed_cidrs" {
  description = "List of CIDR blocks allowed to connect to bastion"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  type        = string
}

# Account ID for IAM role naming
variable "account_id" {
  description = "AWS Account ID"
  type        = string
}
