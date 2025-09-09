variable "cluster_name" {
  description = "Name of the EKS cluster for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Redis will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC for security group rules"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for Redis"
  type        = list(string)
}

variable "redis_node_type" {
  description = "The compute and memory capacity of the nodes"
  type        = string
}

variable "redis_num_cache_nodes" {
  description = "The number of cache nodes"
  type        = number
}

variable "redis_engine_version" {
  description = "Version number of the cache engine"
  type        = string
}

variable "redis_port" {
  description = "The port number on which Redis accepts connections"
  type        = number
  default     = 6379
}
