output "external_dns_role_arn" {
  description = "The ARN of the ExternalDNS IAM role"
  value       = aws_iam_role.external_dns.arn
}

output "external_dns_policy_arn" {
  description = "The ARN of the ExternalDNS IAM policy"
  value       = aws_iam_policy.external_dns.arn
}

output "external_dns_role_name" {
  description = "The name of the ExternalDNS IAM role"
  value       = aws_iam_role.external_dns.name
}
