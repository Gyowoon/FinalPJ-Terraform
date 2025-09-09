# Look up the latest Amazon Linux 2023 AMI for the bastion host
data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  
  filter {
    name   = "image-type"
    values = ["machine"]
  }
}

# Security group for the bastion host
resource "aws_security_group" "bastion" {
  name_prefix = "${var.cluster_name}-bastion-"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-bastion"
  }
}

# IAM role for the bastion host
resource "aws_iam_role" "bastion" {
  name = "bastion-role-${var.account_id}-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for the bastion host - Administrator access
resource "aws_iam_role_policy" "bastion" {
  name = "bastion-policy-${var.account_id}-${var.cluster_name}"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["*"]
        Resource = "*"
      }
    ]
  })
}

# Check if instance profile exists
data "aws_iam_instance_profile" "bastion" {
  count = 0  # This ensures the data source is never queried
  name  = "bastion-profile-${var.account_id}-${var.cluster_name}"
}

# IAM instance profile for the bastion host
resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-profile-${var.account_id}-${var.cluster_name}"
  role = aws_iam_role.bastion.name

  lifecycle {
    create_before_destroy = true
    # Prevent recreation if only the role changes
    ignore_changes = [role]
  }
}

# Bastion EC2 instance
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.bastion.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [
    aws_security_group.bastion.id,
    var.eks_cluster_security_group_id
  ]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  #force_delete               = true  # 인스턴스 강제 삭제 허용

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.cluster_name}-bastion"
    Terraform = "true"
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
    #!/bin/bash
    
    # RSYNC INSTALL
    sudo yum install -y rsync
    
    # DOCKER INSTALL
    sudo yum install -y docker
    sudo systemctl enable --now docker
    sudo usermod -aG docker ec2-user
    newgrp docker

    # KUBECTL INSTALL
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    kubectl version --client

    # HELM INSTALL
    curl -LO https://get.helm.sh/helm-v3.14.4-linux-amd64.tar.gz
    tar -zxvf helm-v3.14.4-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64 helm-v3.14.4-linux-amd64.tar.gz

    # GIT INSTALL
    sudo dnf install -y git

    # MYSQL CLIENT INSTALL
    sudo dnf install -y wget
    sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm
    sudo dnf install -y mysql80-community-release-el9-4.noarch.rpm
    sudo dnf install -y mysql-community-client

    # TERRAFORM INSTALL
    sudo yum install -y yum-utils shadow-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo 
    sudo yum -y install terraform
    terraform version

    # EKSCTL INSTALL
    curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    eksctl version

    # Install AWS IAM Authenticator
    curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.11/aws-iam-authenticator_0.6.11_linux_amd64
    chmod +x ./aws-iam-authenticator
    sudo mv aws-iam-authenticator /usr/local/bin

    # Configure kubeconfig with explicit role
    aws eks update-kubeconfig \
      --region ${var.region} \
      --name ${var.cluster_name} \
      --role-arn ${aws_iam_role.bastion.arn}

    # Set proper permissions for .kube directory
    mkdir -p /home/ec2-user/.kube
    sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
  EOF
}


