variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
}

variable "public_subnet2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
}

variable "private_subnet1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
}

variable "private_subnet2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment tag for all resources"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster for resource tagging"
  type        = string
}

variable "eks_cluster_arn" {
  description = "ARN of the EKS cluster for tagging"
  type        = string
  default     = ""
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}
