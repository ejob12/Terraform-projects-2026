# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "ALB DNS name for accessing services"
  value       = module.load_balancer.alb_dns_name
  sensitive   = false
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.load_balancer.alb_arn
}

# Bastion Host Outputs
output "bastion_public_ip" {
  description = "Bastion Host Public IP"
  value       = module.bastion.bastion_public_ip
}

output "bastion_private_ip" {
  description = "Bastion Host Private IP"
  value       = module.bastion.bastion_private_ip
}

output "bastion_access_command" {
  description = "SSH command to access bastion"
  value       = "ssh -i sept23.perm ec2-user@${module.bastion.bastion_public_ip}"
}

# EKS Cluster Outputs
output "eks_cluster_id" {
  description = "EKS Cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS Cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "configure_kubectl" {
  description = "Command to configure kubectl via bastion"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
}

# Backend Servers Outputs
output "backend_instance_ids" {
  description = "Backend server instance IDs"
  value       = module.backend_servers.backend_instance_ids
}

output "backend_private_ips" {
  description = "Backend server private IPs"
  value       = module.backend_servers.backend_private_ips
}

# Architecture Summary
output "architecture_summary" {
  description = "Three-tier application architecture summary"
  value = {
    tier_1_public = {
      description = "Public tier (Internet-facing)"
      components = [
        "Application Load Balancer (ALB)",
        "Bastion Host for secure access"
      ]
      access = "Via ALB DNS: ${module.load_balancer.alb_dns_name}"
    }
    tier_2_kubernetes = {
      description = "Kubernetes tier (Private - EKS)"
      components = [
        "EKS Cluster with ${var.eks_desired_size} nodes",
        "Services exposed through ALB"
      ]
      access = "Only via Bastion Host"
    }
    tier_3_backend = {
      description = "Backend tier (Private)"
      components = [
        "${var.backend_instance_count} Backend Servers",
        "Databases (MariaDB, PostgreSQL)"
      ]
      access = "From EKS cluster and Bastion only"
    }
  }
}
