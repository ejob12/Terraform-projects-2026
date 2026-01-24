output "group_name" {
  description = "Name of the IAM group"
  value       = aws_iam_group.interns.name
}

output "group_arn" {
  description = "ARN of the IAM group"
  value       = aws_iam_group.interns.arn
}

output "iam_user_names" {
  description = "Names of all created IAM users"
  value       = aws_iam_user.interns[*].name
}

output "iam_user_arns" {
  description = "ARNs of all created IAM users"
  value       = aws_iam_user.interns[*].arn
}

output "iam_user_unique_ids" {
  description = "Unique IDs of all created IAM users"
  value       = aws_iam_user.interns[*].unique_id
}

output "readonly_policy_arn" {
  description = "ARN of the ReadOnly policy attached to the group"
  value       = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

output "console_access_policy_arn" {
  description = "ARN of the custom console access policy"
  value       = aws_iam_policy.console_access_policy.arn
}

output "console_access_policy_name" {
  description = "Name of the custom console access policy"
  value       = aws_iam_policy.console_access_policy.name
}

output "total_users_created" {
  description = "Total number of users created"
  value       = var.user_count
}

output "password_reset_required" {
  description = "Whether password reset is required on first login"
  value       = var.password_reset_required
}

output "console_access_enabled" {
  description = "Whether console access is enabled for users"
  value       = var.enable_console_access
}
