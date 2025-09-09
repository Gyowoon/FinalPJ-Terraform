# VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

# EKS outputs
output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
  
}
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "service_account_name" {
  description = "The name of the shopping mall service account"
  value       = module.eks.service_account_name
}

output "shopping_mall_role_arn" {
  description = "The ARN of the shopping mall IAM role"
  value       = module.eks.shopping_mall_role_arn
}

output "namespace_name" {
  description = "The name of the created Kubernetes namespace"
  value       = module.eks.namespace_name
}

# Bastion outputs
output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_dns" {
  description = "The public DNS name of the bastion host"
  value       = module.bastion.bastion_public_dns
}

# Database outputs
output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.rds.db_instance_endpoint
}

# Redis outputs
output "redis_endpoint" {
  description = "The endpoint of the Redis cluster"
  value       = module.redis.redis_endpoint
}

output "redis_port" {
  description = "The port number of the Redis cluster"
  value       = module.redis.redis_port
}
