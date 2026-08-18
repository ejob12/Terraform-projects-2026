# VPC Module
module "vpc" {
  source = "./modules/vpc"

  cluster_name         = var.cluster_name
  vpc_name             = "${var.cluster_name}-vpc"
  vpc_cidr             = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
}

# EKS Cluster Module
module "eks" {
  source = "./modules/eks"

  cluster_name              = var.cluster_name
  cluster_role_arn          = module.iam.eks_cluster_role_arn
  node_role_arn             = module.iam.eks_node_role_arn
  cluster_security_group_id = module.security_groups.eks_cluster_security_group_id
  node_security_group_id    = module.security_groups.eks_node_security_group_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids         = module.vpc.public_subnet_ids
  kubernetes_version        = var.kubernetes_version
  desired_size              = var.desired_size
  min_size                  = var.min_size
  max_size                  = var.max_size
  instance_types            = [var.instance_type]
  iam_policy_attachments    = []
  node_iam_attachments      = []
}

# Data source to get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}
