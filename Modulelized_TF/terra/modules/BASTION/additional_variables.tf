variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for the bastion instance"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "enable_termination_protection" {
  description = "Enable termination protection for the bastion instance"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for the bastion instance"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "additional_user_data_script" {
  description = "Additional user data script content"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for the bastion instance"
  type        = map(string)
  default     = {}
}

variable "enable_ssm_session_manager" {
  description = "Enable AWS Systems Manager Session Manager for the bastion"
  type        = bool
  default     = true
}
