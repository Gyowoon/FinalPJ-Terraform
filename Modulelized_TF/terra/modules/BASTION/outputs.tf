output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  description = "The public DNS name of the bastion host"
  value       = aws_instance.bastion.public_dns
}

output "bastion_instance_id" {
  description = "The ID of the bastion instance"
  value       = aws_instance.bastion.id
}

output "bastion_security_group_id" {
  description = "The ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "bastion_role_arn" {
  description = "The ARN of the bastion IAM role"
  value       = aws_iam_role.bastion.arn
}

output "bastion_role_name" {
  description = "The name of the bastion IAM role"
  value       = aws_iam_role.bastion.name
}

output "instance_profile_name" {
  description = "The name of the bastion instance profile"
  value       = aws_iam_instance_profile.bastion.name
}
