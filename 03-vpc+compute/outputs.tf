output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = var.vpc_name
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : []
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateways"
  value       = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
}

output "public_security_group_id" {
  description = "ID of the public security group"
  value       = aws_security_group.public_sg.id
}

output "private_security_group_id" {
  description = "ID of the private security group"
  value       = aws_security_group.private_sg.id
}

output "public_instance_ids" {
  description = "IDs of public EC2 instances"
  value       = aws_instance.public[*].id
}

output "public_instance_private_ips" {
  description = "Private IP addresses of public EC2 instances"
  value       = aws_instance.public[*].private_ip
}

output "public_instance_public_ips" {
  description = "Public IP addresses of public EC2 instances"
  value       = aws_instance.public[*].public_ip
}

output "private_instance_ids" {
  description = "IDs of private EC2 instances"
  value       = aws_instance.private[*].id
}

output "private_instance_private_ips" {
  description = "Private IP addresses of private EC2 instances"
  value       = aws_instance.private[*].private_ip
}

output "ami_id" {
  description = "AMI ID used for instances"
  value       = data.aws_ami.amazon_linux_2.id
}

output "ami_name" {
  description = "Name of the AMI used for instances"
  value       = data.aws_ami.amazon_linux_2.name
}

output "instance_type" {
  description = "Instance type used"
  value       = var.instance_type
}

output "total_instances" {
  description = "Total number of instances"
  value       = var.public_instance_count + var.private_instance_count
}
