# -----------------------------------------------------------------------------
# Local variables for unique IAM role names
# -----------------------------------------------------------------------------
locals {
  cluster_role_name_unique  = "${var.cluster_role_name}-${var.account_id}-${var.cluster_name}"
  node_role_name_unique     = "${var.node_role_name}-${var.account_id}-${var.cluster_name}"
  shopping_mall_role_name_unique   = "ShoppingMallPodRole-${var.account_id}-${var.cluster_name}"
  shopping_mall_policy_name_unique = "ShoppingMallPolicy-${var.account_id}-${var.cluster_name}"
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = local.cluster_role_name_unique
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policies" {
  count      = length(var.cluster_policies)
  role       = aws_iam_role.eks_cluster.name
  policy_arn = var.cluster_policies[count.index]
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node" {
  name = local.node_role_name_unique
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  count      = length(var.node_policies)
  role       = aws_iam_role.eks_node.name
  policy_arn = var.node_policies[count.index]
}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = var.subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs    = var.public_access_cidrs
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policies]
}

# EKS Add-ons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "vpc-cni"
  depends_on   = [aws_eks_cluster.eks]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "kube-proxy"
  depends_on   = [aws_eks_cluster.eks]
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "eks-pod-identity-agent"
  depends_on   = [aws_eks_cluster.eks]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "coredns"
  depends_on = [
    aws_eks_node_group.nodes,
    aws_eks_addon.vpc_cni
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.subnet_ids

  ami_type       = "AL2023_x86_64_STANDARD"
  instance_types = ["m7i-flex.large"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 4
    min_size     = 4
    max_size     = 4
  }

  disk_size = 20

  remote_access {
    ec2_ssh_key = var.key_pair_name
  }

  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.node_policies
  ]
}

# Shopping Mall Pod Identity
resource "aws_iam_role" "shopping_mall_role" {
  name = local.shopping_mall_role_name_unique

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "shopping_mall_policy" {
  name = local.shopping_mall_policy_name_unique
  role = aws_iam_role.shopping_mall_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:Connect",
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeReplicationGroups",
          "elasticache:Connect",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "shopping_mall_ecr_policy" {
  role       = aws_iam_role.shopping_mall_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Kubernetes resources
resource "kubernetes_namespace" "shop" {
  metadata {
    name = var.shopping_mall_namespace
  }
  
  depends_on = [
    aws_eks_node_group.nodes,
    aws_eks_addon.coredns,
    aws_eks_cluster.eks
  ]
}

resource "kubernetes_service_account" "shopping_mall" {
  metadata {
    name      = "shopping-mall-sa"
    namespace = kubernetes_namespace.shop.metadata[0].name
  }

  depends_on = [
    kubernetes_namespace.shop,
    aws_eks_node_group.nodes,
    aws_eks_addon.coredns
  ]
}

resource "aws_eks_pod_identity_association" "shopping_mall" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = var.shopping_mall_namespace
  service_account = "shopping-mall-sa"
  role_arn       = aws_iam_role.shopping_mall_role.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role.shopping_mall_role,
    aws_iam_role_policy_attachment.shopping_mall_ecr_policy,
    kubernetes_service_account.shopping_mall
  ]
}
