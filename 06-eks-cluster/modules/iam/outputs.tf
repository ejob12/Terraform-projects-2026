output "eks_cluster_role_arn" {
  description = "EKS Cluster IAM Role ARN"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_cluster_role_name" {
  description = "EKS Cluster IAM Role Name"
  value       = aws_iam_role.eks_cluster_role.name
}

output "eks_node_role_arn" {
  description = "EKS Node IAM Role ARN"
  value       = aws_iam_role.eks_node_role.arn
}

output "eks_node_role_name" {
  description = "EKS Node IAM Role Name"
  value       = aws_iam_role.eks_node_role.name
}

output "eks_node_instance_profile_name" {
  description = "EKS Node Instance Profile Name"
  value       = aws_iam_instance_profile.eks_node_profile.name
}
