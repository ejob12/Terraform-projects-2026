# DEPLOYMENT CHECKLIST - Three Tier Application Architecture

## Pre-Deployment
- [x] Terraform modules created (VPC, Security Groups, IAM, EKS, Load Balancer, Bastion, Backend)
- [x] Configuration files created (versions.tf, variables.tf, terraform.tfvars, outputs.tf, main.tf)
- [x] AWS region set: ca-central-1
- [x] EC2 Key pair configured: sept23.perm

## Architecture Components

### Network Layer (VPC Module)
- VPC CIDR: 10.0.0.0/16
- Public Subnets: 2 subnets (10.0.1.0/24, 10.0.2.0/24) - for ALB and Bastion
- Private Subnets: 3 subnets (10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24) - for EKS and Backend
- NAT Gateways: 2 (one per public subnet for HA)
- Internet Gateway: 1

### Security Layer (Security Groups)
- [x] ALB Security Group: HTTP (80), HTTPS (443) from 0.0.0.0/0
- [x] Bastion Security Group: SSH (22) from 0.0.0.0/0
- [x] EKS Cluster Security Group: Controlled access
- [x] EKS Nodes Security Group: Communication with cluster and ALB
- [x] Backend Security Group: MySQL/PostgreSQL from EKS, SSH from Bastion

### Compute Layer

#### Load Balancer (ALB)
- Type: Application Load Balancer
- Location: Public Subnets
- Ports: 80 (HTTP)
- Target Group: EKS services on port 80
- Access Point: External DNS name for users

#### Bastion Host
- Instance Type: t3.micro
- Location: Public Subnet
- AMI: Amazon Linux 2 (latest)
- Key: sept23.perm
- Elastic IP: Yes
- Purpose: Secure gateway to private EKS cluster

#### EKS Cluster
- Version: 1.34
- Location: Private Subnets
- Endpoint: Private only (accessible only via Bastion)
- Node Group: 2 desired, 1 min, 4 max
- Instance Type: t2.medium
- Logging: API, Audit, Authenticator, ControllerManager, Scheduler

#### Backend Servers
- Instance Count: 2
- Instance Type: t3.small
- Location: Private Subnets
- Purpose: Database and application backend services
- Access: Only from EKS nodes and Bastion

## Deployment Steps

### Step 1: Prepare
```bash
cd 07-three-tier-app
terraform init
```

### Step 2: Plan
```bash
terraform plan -out=tfplan
```

### Step 3: Deploy
```bash
terraform apply tfplan
```

### Step 4: Access Cluster
```bash
# Get bastion public IP
BASTION_IP=$(terraform output -raw bastion_public_ip)

# SSH to bastion
ssh -i sept23.perm ec2-user@$BASTION_IP

# From bastion, configure kubectl
aws eks update-kubeconfig --region ca-central-1 --name three-tier-app-eks

# Test cluster access
kubectl get nodes
```

### Step 5: Configure Service Discovery
```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Services deployed in EKS will be accessible via:
# http://$ALB_DNS
```

## Security Features

✅ **Network Isolation**: Private EKS cluster only accessible via Bastion
✅ **Security Groups**: Least privilege access between tiers
✅ **High Availability**: Multi-AZ deployment for each tier
✅ **NAT Gateway**: Secure outbound connectivity from private subnets
✅ **OIDC Provider**: IRSA support for Kubernetes service accounts
✅ **Encrypted Communication**: Security groups enforce restricted ports

## Access Pattern

```
Internet Users
    ↓
Application Load Balancer (Public Subnets)
    ↓
EKS Cluster (Private Subnets)
    ↓
Backend Servers (Private Subnets)
```

Bastion Host acts as jump host for cluster management:
```
Admin
    ↓
Bastion Host (Public Subnet)
    ↓
EKS Control Plane & Node Groups
```

## Cost Optimization Tips

- Adjust eks_desired_size to reduce running nodes
- Use spot instances for non-critical workloads
- Set up auto-scaling policies
- Use NAT Gateway in single AZ if not needed for HA
- Consider Fargate for EKS if container workloads are variable

## Next Steps After Deployment

1. **Deploy Applications to EKS**:
   - Create Kubernetes namespaces
   - Deploy application workloads
   - Configure ingress controllers

2. **Connect Services**:
   - Configure ALB target registration
   - Set up service mesh (optional)
   - Configure CI/CD pipelines

3. **Monitoring & Logging**:
   - Set up CloudWatch dashboards
   - Configure log aggregation
   - Set up alerts

4. **Security Hardening**:
   - Implement RBAC policies
   - Enable network policies
   - Configure pod security policies

## Troubleshooting

**Cannot SSH to bastion**: Check bastion_allowed_cidr variable
**EKS cluster not accessible**: Ensure kubectl is run from bastion host
**Backend services not accessible**: Verify security groups and network policies
**NAT Gateway not working**: Check route tables in private subnets

## Clean Up

```bash
terraform destroy
```

⚠️ WARNING: This will delete all resources including data
