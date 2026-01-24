variable "app_name" {
  description = "Application name"
  type        = string
}

variable "instance_count" {
  description = "Number of backend instances"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for backend servers"
  type        = string
}
