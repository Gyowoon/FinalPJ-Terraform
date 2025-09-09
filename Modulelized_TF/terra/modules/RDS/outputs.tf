output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.db.id
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.db.endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.db.address
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.db.port
}

output "db_security_group_id" {
  description = "The security group ID"
  value       = aws_security_group.db.id
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = aws_db_subnet_group.db.id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = aws_db_subnet_group.db.arn
}
