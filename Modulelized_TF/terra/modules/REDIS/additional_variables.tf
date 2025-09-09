# Additional Variables for Redis Module Advanced Configuration, Not in use at this moment
variable "snapshot_retention_limit" {
  description = "The number of days for which ElastiCache will retain automatic cache cluster snapshots"
  type        = number
  default     = 7
}

variable "snapshot_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
  default     = "04:00-05:00"
}

variable "maintenance_window" {
  description = "Specifies the weekly time range for maintenance"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "auto_minor_version_upgrade" {
  description = "Specifies whether minor version engine upgrades will be applied automatically"
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "Whether to enable encryption at rest"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Whether to enable encryption in transit"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Specifies whether to enable Multi-AZ Support"
  type        = bool
  default     = false
}

variable "auth_token" {
  description = "Password used to access a password protected server"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "The family of the ElastiCache parameter group"
  type        = string
  default     = "redis7"
}

variable "alarm_cpu_threshold_percent" {
  description = "CPU threshold alarm level"
  type        = number
  default     = 75
}

variable "alarm_memory_threshold_bytes" {
  description = "Memory threshold alarm level"
  type        = number
  default     = 10000000 # 10MB
}

variable "apply_immediately" {
  description = "Specifies whether modifications are applied immediately"
  type        = bool
  default     = false
}
