#!/bin/bash

# Three-Tier Application Architecture Deployment Script
# This script automates the Terraform deployment process

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="three-tier-app"
REGION="us-east-1"

echo "=========================================="
echo "Three-Tier App Deployment Script"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Terraform not found. Please install Terraform.${NC}"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}AWS CLI not found. Please install AWS CLI.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Prerequisites met${NC}"
}

# Initialize Terraform
init_terraform() {
    echo ""
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    cd "$SCRIPT_DIR"
    terraform init
    echo -e "${GREEN}✓ Terraform initialized${NC}"
}

# Validate configuration
validate_config() {
    echo ""
    echo -e "${YELLOW}Validating Terraform configuration...${NC}"
    terraform validate
    echo -e "${GREEN}✓ Configuration is valid${NC}"
}

# Plan deployment
plan_deployment() {
    echo ""
    echo -e "${YELLOW}Planning deployment...${NC}"
    terraform plan -out=tfplan
    echo -e "${GREEN}✓ Plan generated (tfplan)${NC}"
}

# Apply deployment
apply_deployment() {
    echo ""
    echo -e "${YELLOW}Applying Terraform configuration...${NC}"
    echo -e "${YELLOW}This may take 15-20 minutes...${NC}"
    terraform apply tfplan
    echo -e "${GREEN}✓ Deployment complete!${NC}"
}

# Output configuration
output_config() {
    echo ""
    echo -e "${GREEN}=========================================="
    echo "Deployment Complete!"
    echo "==========================================${NC}"
    echo ""
    echo -e "${YELLOW}Access Information:${NC}"
    echo "----------------------------------------"
    
    BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "Not available yet")
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Not available yet")
    EKS_CLUSTER=$(terraform output -raw eks_cluster_id 2>/dev/null || echo "Not available yet")
    
    echo "Bastion Public IP:     $BASTION_IP"
    echo "ALB DNS Name:          $ALB_DNS"
    echo "EKS Cluster:           $EKS_CLUSTER"
    echo ""
    
    echo -e "${YELLOW}SSH to Bastion:${NC}"
    echo "ssh -i sept23.perm ec2-user@$BASTION_IP"
    echo ""
    
    echo -e "${YELLOW}Configure kubectl from Bastion:${NC}"
    echo "aws eks update-kubeconfig --region $REGION --name $EKS_CLUSTER"
    echo ""
    
    echo -e "${YELLOW}Access Your Application:${NC}"
    echo "http://$ALB_DNS"
    echo ""
}

# Main deployment flow
main() {
    case "${1:-deploy}" in
        check)
            check_prerequisites
            ;;
        init)
            check_prerequisites
            init_terraform
            ;;
        plan)
            check_prerequisites
            init_terraform
            validate_config
            plan_deployment
            ;;
        apply)
            check_prerequisites
            init_terraform
            validate_config
            apply_deployment
            output_config
            ;;
        deploy)
            check_prerequisites
            init_terraform
            validate_config
            plan_deployment
            
            echo ""
            echo -e "${YELLOW}Review the plan above. Continue with deployment? (yes/no)${NC}"
            read -r response
            
            if [[ "$response" == "yes" ]]; then
                apply_deployment
                output_config
            else
                echo "Deployment cancelled."
                exit 0
            fi
            ;;
        destroy)
            echo -e "${RED}WARNING: This will destroy all resources!${NC}"
            echo "Type 'yes' to confirm destruction:"
            read -r response
            
            if [[ "$response" == "yes" ]]; then
                terraform destroy
                echo -e "${GREEN}✓ Resources destroyed${NC}"
            else
                echo "Destruction cancelled."
            fi
            ;;
        output)
            terraform output
            ;;
        *)
            echo "Usage: $0 {check|init|plan|apply|deploy|destroy|output}"
            echo ""
            echo "Commands:"
            echo "  check     - Check prerequisites"
            echo "  init      - Initialize Terraform"
            echo "  plan      - Plan deployment"
            echo "  apply     - Apply plan"
            echo "  deploy    - Full deployment (init → plan → apply)"
            echo "  destroy   - Destroy all resources"
            echo "  output    - Show Terraform outputs"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
