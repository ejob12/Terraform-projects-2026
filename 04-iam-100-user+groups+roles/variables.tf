variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

variable "project_name" {
  type        = string
  description = "tech-2026-mtn"
  default     = "2026-terraform-projects"
}

variable "group_name" {
  type        = string
  description = "IAM group name"
  default     = "interns-2026"
}

variable "user_count" {
  type        = number
  description = "Number of IAM users to create"
  default     = 102
}

variable "user_name_prefix" {
  type        = string
  description = "Prefix for IAM user names"
  default     = "intern"
}

variable "enable_console_access" {
  type        = bool
  description = "Enable console access for users"
  default     = true
}

variable "password_reset_required" {
  type        = bool
  description = "Require password reset on first login"
  default     = true
}
