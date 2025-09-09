variable "hosted_zone_ids" {
  description = "List of Route53 hosted zone IDs"
  type        = list(string)
  default     = []
}

variable "domain_filters" {
  description = "List of domain names to filter Route53 zones"
  type        = list(string)
  default     = []
}

variable "policy_name_prefix" {
  description = "Prefix for IAM policy names"
  type        = string
  default     = "external-dns"
}

variable "enable_cross_account" {
  description = "Enable cross-account access for Route53"
  type        = bool
  default     = false
}

variable "cross_account_role_arns" {
  description = "List of cross-account role ARNs to assume"
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_metrics" {
  description = "Enable CloudWatch metrics for ExternalDNS"
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Log level for ExternalDNS"
  type        = string
  default     = "info"
}

variable "sync_interval" {
  description = "Interval between DNS record synchronizations"
  type        = string
  default     = "1m"
}

variable "registry" {
  description = "Registry method to use (txt or noop)"
  type        = string
  default     = "txt"
}

variable "txt_owner_id" {
  description = "TXT record owner ID for external-dns"
  type        = string
  default     = "default"
}
