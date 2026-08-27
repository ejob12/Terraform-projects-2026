variable "backup_dr_region" {
  description = "AWS Region that stores the replicated backup copies"
  type        = string
  default     = "us-west-2"
}

variable "backup_schedule" {
  description = "UTC cron expression for the daily backup window"
  type        = string
  default     = "cron(0 3 * * ? *)"
}

variable "backup_retention_days" {
  description = "Number of days to retain primary recovery points"
  type        = number
  default     = 35
}

variable "backup_copy_retention_days" {
  description = "Number of days to retain cross-Region recovery points"
  type        = number
  default     = 90
}

variable "enable_ami_backups" {
  description = "Create point-in-time AMIs and encrypted copies in the DR Region"
  type        = bool
  default     = false
}

variable "ami_name_prefix" {
  description = "Name prefix for Terraform-managed AMIs"
  type        = string
  default     = "vpc-demo-recovery"
}