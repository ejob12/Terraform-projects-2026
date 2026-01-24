variable "app_name" {
  description = "Application name"
  type        = string
}

variable "cluster_role_arn" {
  description = "EKS cluster role ARN"
  type        = string
}

variable "node_role_arn" {
  description = "EKS node role ARN"
  type        = string
}

variable "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "instance_types" {
  description = "Instance types for worker nodes"
  type        = list(string)
  default     = ["t2.medium"]
}

variable "iam_policy_attachments" {
  description = "IAM policy attachments"
  type        = list(any)
  default     = []
}

variable "node_iam_attachments" {
  description = "Node IAM attachments"
  type        = list(any)
  default     = []
}
