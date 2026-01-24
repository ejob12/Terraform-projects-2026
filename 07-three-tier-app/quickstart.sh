#!/bin/bash
# Quick Start Script for Three-Tier Application Architecture
# Usage: source quickstart.sh or bash quickstart.sh

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Three-Tier Application Architecture - Quick Start          ║"
echo "║  AWS Terraform Deployment                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}[1/5] Checking Prerequisites...${NC}"
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI not found. Please install it first.${NC}"
    echo "  Visit: https://aws.amazon.com/cli/"
    exit 1
fi
echo -e "${GREEN}✓ AWS CLI found${NC}"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform not found. Please install it first.${NC}"
    echo "  Visit: https://www.terraform.io/downloads"
    exit 1
fi
echo -e "${GREEN}✓ Terraform found${NC}"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}⚠ kubectl not found (optional, needed for cluster access)${NC}"
else
    echo -e "${GREEN}✓ kubectl found${NC}"
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}✗ AWS credentials not configured${NC}"
    echo "  Run: aws configure"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials configured${NC}"

# Get AWS account info
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
echo -e "${GREEN}✓ AWS Account: $AWS_ACCOUNT, Region: $AWS_REGION${NC}"
echo ""

# Step 2: Check EC2 Key Pair
echo -e "${BLUE}[2/5] Checking EC2 Key Pair...${NC}"
echo ""

# List available key pairs
KEYPAIRS=$(aws ec2 describe-key-pairs --region $AWS_REGION --query 'KeyPairs[*].KeyName' --output text)

if [ -z "$KEYPAIRS" ]; then
    echo -e "${YELLOW}No EC2 key pairs found. Would you like to create one?${NC}"
    read -p "Enter key pair name: " KEY_PAIR_NAME
    
    if [ -z "$KEY_PAIR_NAME" ]; then
        echo -e "${RED}Key pair name is required${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Creating EC2 key pair: $KEY_PAIR_NAME${NC}"
    aws ec2 create-key-pair \
        --key-name $KEY_PAIR_NAME \
        --region $AWS_REGION \
        --query 'KeyMaterial' \
        --output text > $KEY_PAIR_NAME.pem
    
    chmod 600 $KEY_PAIR_NAME.pem
    echo -e "${GREEN}✓ Key pair created: $KEY_PAIR_NAME.pem${NC}"
else
    echo -e "${GREEN}Available key pairs:${NC}"
    echo "$KEYPAIRS" | tr ' ' '\n' | sed 's/^/  - /'
    echo ""
    
    read -p "Select key pair name: " KEY_PAIR_NAME
    
    if ! echo "$KEYPAIRS" | grep -q "$KEY_PAIR_NAME"; then
        echo -e "${RED}Invalid key pair name${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Key pair selected: $KEY_PAIR_NAME${NC}"
fi
echo ""

# Step 3: Update configuration
echo -e "${BLUE}[3/5] Updating Configuration...${NC}"
echo ""

# Get current public IP
PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)
echo "Your current public IP: $PUBLIC_IP"
echo ""

read -p "Enter SSH access CIDR (default: 0.0.0.0/0): " BASTION_CIDR
BASTION_CIDR=${BASTION_CIDR:-0.0.0.0/0}

# Update terraform.tfvars
echo -e "${BLUE}Updating terraform.tfvars...${NC}"

cat > terraform.tfvars.tmp <<EOF
# AWS Configuration
aws_region = "$AWS_REGION"
environment = "prod"
app_name = "three-tier-app"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["${AWS_REGION}a", "${AWS_REGION}b", "${AWS_REGION}d"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# Bastion Configuration
bastion_allowed_cidr = ["$BASTION_CIDR"]
bastion_key_pair_name = "$KEY_PAIR_NAME"

# EKS Configuration
kubernetes_version = "1.34"
eks_desired_size = 2
eks_min_size = 1
eks_max_size = 4
eks_instance_type = "t2.medium"

# Backend Servers Configuration
backend_instance_count = 2
backend_instance_type = "t3.small"
EOF

mv terraform.tfvars.tmp terraform.tfvars
echo -e "${GREEN}✓ Configuration updated${NC}"
echo ""

# Step 4: Initialize and Plan
echo -e "${BLUE}[4/5] Initializing Terraform...${NC}"
echo ""

terraform init

echo ""
terraform validate

echo ""
echo -e "${BLUE}Generating Terraform plan...${NC}"
terraform plan -out=tfplan

echo ""

# Step 5: Apply configuration
echo -e "${BLUE}[5/5] Deploying Infrastructure...${NC}"
echo ""
echo -e "${YELLOW}This will deploy the three-tier architecture and may incur AWS costs.${NC}"
read -p "Do you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Deploying infrastructure... This will take 20-30 minutes${NC}"
echo ""

terraform apply tfplan

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Deployment Complete!                               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Display outputs
echo -e "${BLUE}Deployment Information:${NC}"
echo ""

BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "N/A")
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "N/A")
CLUSTER_NAME=$(terraform output -raw eks_cluster_id 2>/dev/null || echo "N/A")

echo -e "  ${YELLOW}Bastion Host:${NC}"
echo "    Public IP: $BASTION_IP"
echo "    Access: ssh -i $KEY_PAIR_NAME.pem ec2-user@$BASTION_IP"
echo ""

echo -e "  ${YELLOW}Application Load Balancer:${NC}"
echo "    DNS: $ALB_DNS"
echo "    Access: http://$ALB_DNS"
echo ""

echo -e "  ${YELLOW}EKS Cluster:${NC}"
echo "    Name: $CLUSTER_NAME"
echo "    Region: $AWS_REGION"
echo ""

echo -e "  ${YELLOW}Next Steps:${NC}"
echo "    1. SSH to bastion: ssh -i $KEY_PAIR_NAME.pem ec2-user@$BASTION_IP"
echo "    2. Configure kubectl:"
echo "       aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME"
echo "    3. Access cluster:"
echo "       kubectl get nodes"
echo "    4. Access applications:"
echo "       curl http://$ALB_DNS"
echo ""

echo -e "  ${YELLOW}Documentation:${NC}"
echo "    - README.md: Complete documentation"
echo "    - DEPLOYMENT_GUIDE.md: Step-by-step guide"
echo "    - ARCHITECTURE.md: Design patterns"
echo "    - SUMMARY.md: Quick reference"
echo ""

echo -e "${GREEN}For more information, see the documentation files.${NC}"
echo ""
