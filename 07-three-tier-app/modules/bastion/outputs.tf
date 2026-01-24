output "bastion_public_ip" {
  description = "Bastion Host Public IP"
  value       = aws_eip.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Bastion Host Private IP"
  value       = aws_instance.bastion.private_ip
}

output "bastion_instance_id" {
  description = "Bastion Instance ID"
  value       = aws_instance.bastion.id
}
