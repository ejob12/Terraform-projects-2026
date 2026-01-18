output "iam_user_name" {
  description = "Name of the IAM user"
  value       = aws_iam_user.prof_prince.name
}

output "iam_user_arn" {
  description = "ARN of the IAM user"
  value       = aws_iam_user.prof_prince.arn
}

output "iam_group_name" {
  description = "Name of the IAM group"
  value       = aws_iam_group.admin_group.name
}

output "iam_group_arn" {
  description = "ARN of the IAM group"
  value       = aws_iam_group.admin_group.arn
}

output "compute_policy_arn" {
  description = "ARN of the compute full access policy"
  value       = aws_iam_policy.compute_full_access.arn
}

output "compute_policy_name" {
  description = "Name of the compute full access policy"
  value       = aws_iam_policy.compute_full_access.name
}
