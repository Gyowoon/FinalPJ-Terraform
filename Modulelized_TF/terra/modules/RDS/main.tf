# ---------------------------------------------------------------------------
# MySQL RDS resources
#
# The following resources create a MySQL RDS instance in the private
# subnets.  A dedicated security group restricts inbound connections to
# within the VPC CIDR block, and a subnet group ensures the instance is
# placed into the private subnets.  The master credentials and DB name are
# supplied via variables.  Final snapshots are skipped on deletion for
# simplicity in development environments.
# ---------------------------------------------------------------------------

# Security group for RDS
resource "aws_security_group" "db" {
  name_prefix = "${var.cluster_name}-db-"
  description = "Security group for MySQL RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MySQL access from within the VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-db"
  }
}

# Subnet group for RDS
resource "aws_db_subnet_group" "db" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

# MySQL RDS instance
resource "aws_db_instance" "db" {
  identifier           = "${var.cluster_name}-db"
  engine              = "mysql"
  engine_version      = var.db_engine_version
  instance_class      = var.db_instance_class
  allocated_storage   = var.db_allocated_storage
  storage_type        = "gp3"

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  
  username              = var.db_master_username
  password              = var.db_master_password
  db_name              = var.db_name
  
  multi_az             = false
  publicly_accessible  = false
  skip_final_snapshot  = true
  deletion_protection  = false
  apply_immediately    = true

  tags = {
    Name = "${var.cluster_name}-db"
  }
}
