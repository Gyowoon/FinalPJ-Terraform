output "redis_cluster_id" {
  description = "The ID of the ElastiCache cluster"
  value       = aws_elasticache_cluster.redis.id
}

output "redis_endpoint" {
  description = "The cache nodes endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "The port number of the Redis cluster"
  value       = aws_elasticache_cluster.redis.port
}

output "redis_security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.redis.id
}

output "redis_subnet_group_name" {
  description = "The name of the subnet group"
  value       = aws_elasticache_subnet_group.redis.name
}

output "redis_parameter_group_name" {
  description = "The name of the parameter group"
  value       = aws_elasticache_parameter_group.redis.name
}
