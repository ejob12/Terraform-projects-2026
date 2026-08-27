# Three-Tier Application Architecture on AWS

A complete, production-ready three-tier application architecture deployed on AWS using Terraform modules.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    PUBLIC SUBNET(S)                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Tier 1: Presentation Layer                          │   │
│  │  • Application Load Balancer (ALB)                  │   │
│  │  • Bastion Host (Jump Server)                       │   │
│  └──────────────────────────────────────────────────────┘   │
│  NAT Gateway for private subnet egress                      │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   PRIVATE SUBNET(S)                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Tier 2: Application Layer (EKS Cluster)            │   │
│  │  • EKS Control Plane (Managed)                      │   │
│  │  • 2-4 Worker Nodes (t2.medium)                     │   │
│  │  • Services discovered via ALB Target Group         │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Tier 3: Data Layer                                  │   │
│  │  • Backend Servers (EC2 instances)                  │   │
│  │  • MariaDB / PostgreSQL                             │   │
│  │  • In-memory caching                                │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Security Architecture

### Network Isolation
- **Public Subnets**: ALB and Bastion Host only
- **Private Subnets**: EKS cluster and backend servers
- **NAT Gateway**: Outbound internet access for private subnets
- **No Direct Internet Access**: Private subnets only access internet through NAT

### Access Control
- **Bastion Host**: SSH access from allowed CIDR blocks (default: 0.0.0.0/0, restrict in production)
- **EKS Cluster**: Private endpoint only, no public access
- **Backend Servers**: Only accessible from EKS cluster and Bastion host
- **Security Groups**: Fine-grained ingress/egress rules per tier

### Service Discovery
- **ALB Target Group**: Automatically registers EKS service endpoints
- **Service Ingress Controller**: Deploy nginx-ingress or ALB ingress controller in EKS
- **Internal DNS**: Backend servers accessible via private Route53 or service discovery

## Module Structure

```
07-three-tier-app/
├── modules/
│   ├── vpc/                    # VPC, subnets, routing, NAT
│   ├── security-groups/        # Security group configuration
│   ├── bastion/               # Bastion host in public subnet
│   ├── load-balancer/         # Application Load Balancer
│   ├── eks/                   # EKS cluster in private subnet
│   ├── backend-servers/       # Backend servers in private subnet
│   └── iam/                   # IAM roles and policies
├── main.tf                    # Root module composition
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Provider configuration
└── terraform.tfvars           # Variable values
```

## Prerequisites

1. **AWS Account**: Active AWS account with appropriate permissions
2. **Terraform**: Version 1.0 or higher
3. **AWS CLI**: Configured with credentials
4. **kubectl**: For Kubernetes cluster management
5. **EC2 Key Pair**: Created in your AWS region
6. **Helm**: Optional, for package management in EKS

## Configuration

### Before Deployment

1. **Update terraform.tfvars**:
   ```hcl
   bastion_key_pair_name = "your-ec2-keypair-name"
   bastion_allowed_cidr = ["YOUR.IP.ADDRESS/32"]  # Restrict SSH access
   ```

2. **Create EC2 Key Pair** (if not exists):
   ```bash
   aws ec2 create-key-pair --key-name your-keypair-name \
    --region us-east-1 \
     --query 'KeyMaterial' --output text > your-keypair-name.pem
   chmod 600 your-keypair-name.pem
   ```

## Deployment Steps

### 1. Initialize Terraform

```bash
cd 07-three-tier-app
terraform init
```

### 2. Validate Configuration

```bash
terraform validate
terraform fmt -recursive
```

### 3. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan output carefully.

### 4. Apply Configuration

```bash
terraform apply tfplan
```

**Deployment time**: ~20-30 minutes

### 5. Retrieve Outputs

```bash
terraform output
```

Key outputs:
- `alb_dns_name`: Access applications here
- `bastion_public_ip`: Connect to bastion
- `eks_cluster_id`: Kubernetes cluster name
- `configure_kubectl`: Command to configure kubectl

## Post-Deployment Setup

### 1. Configure kubectl via Bastion

```bash
# SSH to bastion
ssh -i your-keypair-name.pem ec2-user@<bastion_public_ip>

# On bastion, configure AWS CLI
aws configure

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>

# Verify cluster access
kubectl get nodes
```

### 2. Deploy Ingress Controller (Recommended)

```bash
# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster-name> \
  --set serviceAccount.create=true
```

### 3. Create Sample Application

```bash
# Create a test deployment
kubectl create deployment web --image=nginx --port=80

# Expose via service
kubectl expose deployment web --type=LoadBalancer --name=web-service
```

## Access Patterns

### Accessing Applications
```
Internet → ALB DNS Name → ALB Target Group → EKS Service → Pods
```

### Accessing EKS Cluster
```
Laptop → Bastion Host (SSH) → kubectl via bastion
```

### Backend Database Access
```
EKS Pods → Backend Servers (Private Subnet) → Database
Bastion → Backend Servers (22) → Database
```

## Network CIDR Allocation

| Component | CIDR | Subnet Type |
|-----------|------|------------|
| VPC | 10.0.0.0/16 | - |
| Public Subnet 1 | 10.0.1.0/24 | us-east-1a |
| Public Subnet 2 | 10.0.2.0/24 | us-east-1b |
| Private Subnet 1 | 10.0.11.0/24 | us-east-1a |
| Private Subnet 2 | 10.0.12.0/24 | us-east-1b |
| Private Subnet 3 | 10.0.13.0/24 | us-east-1c |

## Customization

### Scale EKS Cluster

Edit `terraform.tfvars`:
```hcl
eks_desired_size = 3    # Increase from 2
eks_max_size = 5        # Increase from 4
eks_instance_type = "t3.medium"  # Larger instance
```

### Add Backend Servers

```hcl
backend_instance_count = 4  # Increase from 2
```

### Add Public Subnets

```hcl
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
```

Then reapply:
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Monitoring & Logging

### EKS Control Plane Logs

Enabled automatically for:
- API server
- Audit logs
- Authenticator
- Controller manager
- Scheduler

View in CloudWatch:
```bash
aws logs describe-log-groups --query 'logGroups[*].logGroupName'
```

### ALB Logs

Enable manually if needed:
```bash
# Configure S3 bucket and ALB logging
```

## Security Best Practices

1. **Restrict Bastion Access**: Update `bastion_allowed_cidr` to your IP only
2. **Enable IMDSv2**: Configured automatically in bastion
3. **Network Policies**: Deploy Calico or Cilium for pod-level security
4. **RBAC**: Implement role-based access control in Kubernetes
5. **Secrets Management**: Use AWS Secrets Manager or Vault
6. **Image Registry**: Use private ECR with image scanning
7. **Backup**: Enable automated EBS backups

## Cost Estimation

### Monthly Costs (Approximate)

| Component | Quantity | Cost |
|-----------|----------|------|
| EKS Control Plane | 1 | $73 |
| EC2 t2.medium (nodes) | 2 | $60 |
| EC2 t3.small (backend) | 2 | $30 |
| EC2 t3.micro (bastion) | 1 | $8 |
| ALB | 1 | $22 |
| NAT Gateway | 2 | $64 |
| Data Transfer | - | $15-30 |
| **Total** | | **$270-290** |

## Destroying Resources

⚠️ **WARNING**: This will delete all resources including data

```bash
# Destroy in order
terraform destroy

# Or destroy specific modules
terraform destroy -target=module.backend_servers
terraform destroy -target=module.eks
terraform destroy -target=module.bastion
terraform destroy -target=module.load_balancer
terraform destroy -target=module.security_groups
terraform destroy -target=module.vpc
```

## Troubleshooting

### Nodes not joining cluster
1. Check security group rules between cluster and nodes
2. Verify IAM role policies are attached
3. Check CloudWatch logs: `/aws/eks/cluster-name/cluster`

### kubectl cannot connect
1. Ensure kubeconfig is updated
2. Verify cluster endpoint is accessible from bastion
3. Check security group allows port 443

### ALB not routing to services
1. Deploy ingress controller
2. Create ingress resources pointing to services
3. Check target group health checks

### Backend services cannot access database
1. Verify security group rules allow traffic
2. Check network ACLs in private subnets
3. Verify database server is running

## References

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [Container Networking with CNI](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)

## Support

For issues or questions:
1. Check CloudWatch logs
2. Verify security groups and network connectivity
3. Review Terraform state: `terraform state list`
4. Enable debug logging: `TF_LOG=DEBUG terraform apply`
