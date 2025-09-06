// This Terraform configuration augments the original EKS/Bastion setup by
// adding an IAM role and instance profile for the bastion host, mapping
// that role into the EKS cluster's RBAC via an access entry, and
// defining ECR repositories for the application.  It assumes the
// original resources (VPC, cluster, etc.) are defined in main-updated.tf.

// IAM role for the bastion host.  This role allows the bastion to
// authenticate to ECR (for pushing/pulling images) and to the EKS
// cluster (for kubeconfig generation and kubectl operations).  The
// policies attached here are intentionally broad; in a production
// environment you may wish to scope these down.
resource "aws_iam_role" "bastion" {
  name = "${var.cluster_name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

// Attach managed policies granting ECR push/pull and EKS control
resource "aws_iam_role_policy_attachment" "bastion_policies" {
  for_each = {
    #ecr = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser" # ECR Policy
    #eks = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" # EKS Policy 
    admin = "arn:aws:iam::aws:policy/AdministratorAccess" # ADMIN Policy  
  }
  role       = aws_iam_role.bastion.name
  policy_arn = each.value
}

// Instance profile binding the bastion role
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.cluster_name}-bastion-profile"
  role = aws_iam_role.bastion.name
}

// Access entry mapping the bastion role into the EKS cluster RBAC.  It
// grants the role membership in the below group so that
// kubectl commands executed on the bastion will have cluster‑admin
// privileges.  Requires AWS CLI v2 and IAM Access Entry feature.
resource "aws_eks_access_entry" "bastion" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.bastion.arn
  kubernetes_groups = ["eks-admins"] # GYO-2040
}

// Define ECR repositories for the backend and frontend if they do not
// already exist.  These resources ensure the repositories are created
// before the deployment script runs.
resource "aws_ecr_repository" "shop_backend" {
  name                 = "shop-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = { Name = "shop-backend" }
}

resource "aws_ecr_repository" "shop_frontend" {
  name                 = "shop-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = { Name = "shop-frontend" }
}
