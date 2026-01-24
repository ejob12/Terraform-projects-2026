output "backend_instance_ids" {
  description = "Backend instance IDs"
  value       = aws_instance.backend[*].id
}

output "backend_private_ips" {
  description = "Backend server private IPs"
  value       = aws_instance.backend[*].private_ip
}
