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

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : []
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateways"
  value       = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web_sg.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db_sg.id
}

output "web_instance_ids" {
  description = "IDs of web EC2 instances"
  value       = aws_instance.web[*].id
}

output "web_instance_private_ips" {
  description = "Private IP addresses of web EC2 instances"
  value       = aws_instance.web[*].private_ip
}

output "web_instance_public_ips" {
  description = "Public IP addresses of web EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "db_instance_ids" {
  description = "IDs of DB EC2 instances"
  value       = aws_instance.db[*].id
}

output "db_instance_private_ips" {
  description = "Private IP addresses of DB EC2 instances"
  value       = aws_instance.db[*].private_ip
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

output "key_pair_name" {
  description = "SSH key pair name"
  value       = var.key_name
}

output "total_instances" {
  description = "Total number of instances"
  value       = var.web_server_count + var.db_server_count
}

output "web_server_count" {
  description = "Number of web servers"
  value       = var.web_server_count
}

output "db_server_count" {
  description = "Number of DB servers"
  value       = var.db_server_count
}

output "ssh_into_web_server" {
  description = "SSH command to connect to web server (example)"
  value       = "ssh -i /path/to/${var.key_name}.pem ec2-user@${try(aws_instance.web[0].public_ip, "PUBLIC_IP")}"
}

output "ssh_from_web_to_db" {
  description = "SSH command to connect to DB server from web server (example)"
  value       = "ssh -i /path/to/${var.key_name}.pem ec2-user@${try(aws_instance.db[0].private_ip, "PRIVATE_IP")}"
}
