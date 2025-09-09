# ---------------------------------------------------------------------------
# Route53 및 ExternalDNS 설정
# ---------------------------------------------------------------------------

# ExternalDNS IAM Policy
resource "aws_iam_policy" "external_dns" {
  name        = "external-dns-route53-policy-${var.account_id}-${var.cluster_name}"
  description = "Allow ExternalDNS to manage Route53 records"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["route53:ChangeResourceRecordSets"]
        Resource = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
      }
    ]
  })

  tags = {
    Name = "external-dns-policy"
    Cluster = var.cluster_name
  }
}

# ExternalDNS IAM Role
resource "aws_iam_role" "external_dns" {
  name = "external-dns-pod-identity-role-${var.account_id}-${var.cluster_name}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })

  tags = {
    Name = "external-dns-role"
    Cluster = var.cluster_name
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

# ExternalDNS Pod Identity Association
resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "external-dns"
  role_arn       = aws_iam_role.external_dns.arn

  depends_on = [var.eks_cluster_id]  # EKS 클러스터가 생성된 후에 생성되도록 의존성 추가
}
