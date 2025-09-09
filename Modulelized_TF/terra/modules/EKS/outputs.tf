output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.eks.id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.eks.arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
  
}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster"
  value       = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority" {
  description = "The certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

output "node_group_arn" {
  description = "The ARN of the EKS node group"
  value       = aws_eks_node_group.nodes.arn
}

output "shopping_mall_role_arn" {
  description = "The ARN of the shopping mall IAM role"
  value       = aws_iam_role.shopping_mall_role.arn
}

output "namespace_name" {
  description = "The name of the created Kubernetes namespace"
  value       = kubernetes_namespace.shop.metadata[0].name
}

output "service_account_name" {
  description = "The name of the created Kubernetes service account"
  value       = kubernetes_service_account.shopping_mall.metadata[0].name
}
