# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  app_name             = var.app_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  app_name             = var.app_name
  vpc_id               = module.vpc.vpc_id
  bastion_allowed_cidr = var.bastion_allowed_cidr
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  app_name = var.app_name
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load-balancer"

  app_name              = var.app_name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
}

# Bastion Host Module
module "bastion" {
  source = "./modules/bastion"

  app_name          = var.app_name
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  security_group_id = module.security_groups.bastion_security_group_id
  key_pair_name     = var.bastion_key_pair_name
}

# EKS Module (Private Subnet)
module "eks" {
  source = "./modules/eks"

  app_name                  = var.app_name
  cluster_role_arn          = module.iam.eks_cluster_role_arn
  node_role_arn             = module.iam.eks_node_role_arn
  cluster_security_group_id = module.security_groups.eks_cluster_security_group_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids         = module.vpc.public_subnet_ids
  kubernetes_version        = var.kubernetes_version
  desired_size              = var.eks_desired_size
  min_size                  = var.eks_min_size
  max_size                  = var.eks_max_size
  instance_types            = [var.eks_instance_type]
  iam_policy_attachments    = []
  node_iam_attachments      = []
}

# Backend Servers Module (Private Subnet)
module "backend_servers" {
  source = "./modules/backend-servers"

  app_name           = var.app_name
  instance_count     = var.backend_instance_count
  instance_type      = var.backend_instance_type
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security_groups.backend_security_group_id
}
