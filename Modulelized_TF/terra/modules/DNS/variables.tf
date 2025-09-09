variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "hosted_zone_id" {
  description = "ID of the Route53 hosted zone"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "eks_cluster_id" {
  description = "ID of the EKS cluster"
  type        = string
}
