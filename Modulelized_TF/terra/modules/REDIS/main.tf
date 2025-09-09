# ---------------------------------------------------------------------------
# ElastiCache (Redis) resources
#
# This section provisions a single-node Redis cluster in the private
# subnets.  A security group restricts inbound connections to the VPC CIDR
# block.  The subnet group ensures the cluster is created in the private
# subnets.  For more advanced configurations, you can convert this to a
# replication group with multiple nodes.
# ---------------------------------------------------------------------------

# Security group for Redis
resource "aws_security_group" "redis" {
  name_prefix = "${var.cluster_name}-redis-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow Redis access from within the VPC"
    from_port   = var.redis_port
    to_port     = var.redis_port
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
    Name = "${var.cluster_name}-redis"
  }
}

# Subnet group for Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.cluster_name}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.cluster_name}-redis-subnet-group"
  }
}

# Parameter group for Redis
resource "aws_elasticache_parameter_group" "redis" {
  family = "redis7"
  name   = "${var.cluster_name}-redis-params"

  # You can add custom Redis parameters here if needed
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = {
    Name = "${var.cluster_name}-redis-params"
  }
}

# Redis cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.cluster_name}-redis"
  engine              = "redis"
  engine_version      = var.redis_engine_version
  node_type           = var.redis_node_type
  num_cache_nodes     = var.redis_num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  port                = var.redis_port
  
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]

  # Some recommended settings
  auto_minor_version_upgrade = true
  maintenance_window        = "sun:05:00-sun:06:00"
  snapshot_window          = "04:00-05:00"
  snapshot_retention_limit = 7

  tags = {
    Name = "${var.cluster_name}-redis"
  }
}
