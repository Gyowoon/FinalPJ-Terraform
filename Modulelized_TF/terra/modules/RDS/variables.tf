variable "cluster_name" {
  description = "Name of the EKS cluster for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where RDS will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC for security group rules"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
}

variable "db_engine_version" {
  description = "The engine version to use"
  type        = string
}

variable "db_master_username" {
  description = "Username for the master DB user"
  type        = string
}

variable "db_master_password" {
  description = "Password for the master DB user"
  type        = string
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
}
