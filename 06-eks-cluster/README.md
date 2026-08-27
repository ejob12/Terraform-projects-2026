# EKS Cluster Deployment with Terraform

This Terraform configuration deploys a complete EKS cluster in `us-east-1` with all required infrastructure using modular architecture.

## Architecture Overview

The deployment includes:
- **VPC Module**: VPC with public and private subnets across 3 AZs
- **IAM Module**: Service roles and policies for EKS cluster and nodes
- **Security Groups Module**: Network security configuration
- **EKS Module**: EKS cluster with managed node groups

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. kubectl installed for cluster management
4. Helm (optional, for package management)

## Configuration

### Default Settings
- **Region**: us-east-1
- **Instance Type**: t2.medium
- **Desired Nodes**: 2
- **Min Nodes**: 1
- **Max Nodes**: 4
- **Kubernetes Version**: 1.28

### Customization

Edit `terraform.tfvars` to customize:

```hcl
aws_region      = "us-east-1"
cluster_name    = "eks-cluster-ca"
desired_size    = 2
min_size        = 1
max_size        = 4
instance_type   = "t2.medium"
```

## Deployment Steps

### 1. Initialize Terraform

```bash
cd 06-eks-cluster
terraform init
```

### 2. Validate Configuration

```bash
terraform validate
```

### 3. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan to ensure all resources are correct.

### 4. Apply Configuration

```bash
terraform apply tfplan
```

This will:
- Create VPC with subnets, routing tables, and NAT gateways
- Set up IAM roles and policies
- Create security groups
- Deploy EKS cluster
- Create managed node group with t2.medium instances

**Deployment time**: ~15-20 minutes

### 5. Configure kubectl

After deployment completes, run:

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-cluster-ca
```

Or use the output from Terraform:

```bash
terraform output configure_kubectl
```

### 6. Verify Cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Module Structure

```
06-eks-cluster/
├── modules/
│   ├── vpc/                 # VPC and networking
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/                 # IAM roles and policies
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-groups/     # Security group configuration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── eks/                 # EKS cluster and node groups
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf                  # Root module configuration
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── versions.tf              # Provider configuration
└── terraform.tfvars         # Variable values
```

## Important Outputs

After deployment, Terraform outputs:

- `cluster_id`: EKS Cluster name
- `cluster_endpoint`: Kubernetes API endpoint
- `cluster_version`: Kubernetes version
- `vpc_id`: VPC ID
- `node_group_id`: Node group ID
- `configure_kubectl`: Command to configure kubectl

## Network Architecture

### VPC Layout
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- **Private Subnets**: 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
- **NAT Gateways**: One per AZ in public subnets
- **Route Tables**: Separate routing for public and private traffic

## Destroying the Cluster

⚠️ **WARNING**: This will delete all resources including data

```bash
terraform destroy
```

## Cost Estimation

Typical monthly costs for this configuration:
- EKS Control Plane: ~$73/month
- 2 x t2.medium EC2 instances: ~$50-60/month
- NAT Gateway: ~$32/month
- Data transfer and storage: ~$10-20/month

**Total estimate**: ~$165-185/month

## Troubleshooting

### Nodes not joining cluster
- Check security group rules between cluster and nodes
- Verify IAM role policies are attached correctly
- Check CloudWatch logs in `/aws/eks/eks-cluster-ca/cluster`

### kubectl connection issues
- Ensure AWS CLI is configured correctly
- Verify kubeconfig was updated: `kubectl config view`
- Check cluster endpoint is accessible

### Terraform state issues
- Enable S3 backend (uncomment in versions.tf) for production
- Use DynamoDB table for state locking

## Best Practices

1. **State Management**: Use S3 backend with encryption and DynamoDB locks
2. **Monitoring**: Enable EKS control plane logging
3. **Auto-scaling**: Configure Kubernetes autoscaler for node scaling
4. **RBAC**: Implement proper RBAC policies for cluster access
5. **Network Policies**: Deploy network policies for workload isolation
6. **Ingress Controller**: Deploy NGINX or ALB ingress controller

## Support & Documentation

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
