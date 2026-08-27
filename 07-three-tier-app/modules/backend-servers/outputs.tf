output "backend_instance_ids" {
  description = "Backend instance IDs"
  value       = aws_instance.backend[*].id
}

output "backend_instance_arns" {
  description = "Backend instance ARNs"
  value       = aws_instance.backend[*].arn
}

output "backend_private_ips" {
  description = "Backend server private IPs"
  value       = aws_instance.backend[*].private_ip
}
