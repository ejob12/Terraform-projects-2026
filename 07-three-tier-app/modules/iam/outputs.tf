output "eks_cluster_role_arn" {
  description = "EKS cluster role ARN"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_role_arn" {
  description = "EKS node role ARN"
  value       = aws_iam_role.eks_node_role.arn
}

output "eks_node_instance_profile_name" {
  description = "EKS node instance profile name"
  value       = aws_iam_instance_profile.eks_node_profile.name
}
