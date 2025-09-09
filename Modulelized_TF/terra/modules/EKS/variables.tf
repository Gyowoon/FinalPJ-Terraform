variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "cluster_role_name" {
  description = "Name of the IAM role for the EKS cluster"
  type        = string
}

variable "node_role_name" {
  description = "Name of the IAM role for the EKS node group"
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "cluster_policies" {
  description = "List of IAM policy ARNs to attach to the EKS cluster role"
  type        = list(string)
}

variable "node_policies" {
  description = "List of IAM policy ARNs to attach to the EKS node role"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster API server"
  type        = list(string)
}

variable "key_pair_name" {
  description = "Name of the key pair for EC2 instances in the node group"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

# Shopping Mall Pod Identity variables
variable "shopping_mall_namespace" {
  description = "Kubernetes namespace for shopping mall application"
  type        = string
  default     = "shop"
}
