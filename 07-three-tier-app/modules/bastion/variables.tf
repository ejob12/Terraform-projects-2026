variable "app_name" {
  description = "Application name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion"
  type        = string
  default     = "t3.micro"
}

variable "public_subnet_id" {
  description = "Public subnet ID for bastion"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for bastion"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for bastion access"
  type        = string
}
