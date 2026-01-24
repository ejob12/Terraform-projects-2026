variable "app_name" {
  description = "Application name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "bastion_allowed_cidr" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
