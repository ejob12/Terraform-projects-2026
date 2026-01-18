variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ca-central-1"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "2026-terraform-projects"
}

variable "vpc_name" {
  type        = string
  description = "VPC name"
  default     = "compute-vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
  default     = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones"
  default     = ["ca-central-1a", "ca-central-1b"]
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "public_instance_count" {
  type        = number
  description = "Number of instances in public subnets"
  default     = 10
}

variable "private_instance_count" {
  type        = number
  description = "Number of instances in private subnets"
  default     = 2
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable NAT gateway for private subnets"
  default     = true
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in VPC"
  default     = true
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS support in VPC"
  default     = true
}

# Data source to fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
