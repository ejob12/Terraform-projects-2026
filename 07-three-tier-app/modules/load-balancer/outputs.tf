output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "Target Group ARN for EKS services"
  value       = aws_lb_target_group.eks_services.arn
}

output "target_group_name" {
  description = "Target Group Name"
  value       = aws_lb_target_group.eks_services.name
}
