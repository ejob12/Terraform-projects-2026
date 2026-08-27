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