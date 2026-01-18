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
  description = "Project name"
  default     = "2026-terraform-projects"
}

variable "iam_user_name" {
  type        = string
  description = "IAM user name"
  default     = "prof-prince-2026"
}

variable "iam_group_name" {
  type        = string
  description = "IAM group name"
  default     = "2026-admin"
}
