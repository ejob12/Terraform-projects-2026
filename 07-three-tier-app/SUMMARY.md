# Three-Tier Application Architecture - Project Summary

## 📋 Project Overview

A complete, production-ready three-tier application architecture deployed on AWS using Terraform modules with:
- **Load Balancer** (Application Layer)
- **EKS Cluster** (Application/Container Layer - Private)
- **Backend Servers** (Data Layer - Private)
- **Bastion Host** (Access Gateway)
- **Full VPC with Public/Private Subnets**

## 🏗️ Architecture Components

### Tier 1: Public Presentation Layer
| Component | Details |
|-----------|---------|
| **Load Balancer** | AWS Application Load Balancer (ALB) |
| **Target Group** | Routes traffic to EKS service pods |
| **Bastion Host** | t3.micro in public subnet for cluster access |
| **Networking** | 2 public subnets across AZs |
| **Access** | Port 80/443 from internet, SSH restricted |

### Tier 2: Private Application Layer  
| Component | Details |
|-----------|---------|
| **EKS Cluster** | Managed Kubernetes service |
| **Worker Nodes** | 2-4 t2.medium instances (configurable) |
| **Auto-Scaling** | Min: 1, Max: 4 nodes |
| **Networking** | 3 private subnets across AZs |
| **Access** | Private endpoint only, via bastion/VPN |
| **Version** | Kubernetes 1.34 |

### Tier 3: Private Data Layer
| Component | Details |
|-----------|---------|
| **Backend Servers** | 2+ t3.small EC2 instances |
| **Pre-installed** | Docker, MariaDB client, PostgreSQL client |
| **Databases** | MariaDB, PostgreSQL ready |
| **Networking** | Private subnets, NAT Gateway egress |
| **Access** | From EKS pods (3306, 5432) + Bastion SSH |

## 📁 Module Structure

```
07-three-tier-app/
├── modules/
│   ├── vpc/                 # VPC, subnets, NAT, routing (13 resources)
│   ├── security-groups/     # 5 security groups + rules (11 resources)
│   ├── iam/                 # IAM roles, policies, profiles (8 resources)
│   ├── bastion/            # Bastion host + EIP (3 resources)
│   ├── load-balancer/      # ALB + target group + listener (4 resources)
│   ├── eks/                # EKS cluster + node group + OIDC (4 resources)
│   └── backend-servers/    # EC2 instances + user data (2+ resources)
├── main.tf                 # Root module orchestration
├── variables.tf            # Input variables (20+)
├── outputs.tf              # Output values (15+)
├── versions.tf             # Provider configuration
├── terraform.tfvars        # Variable values
├── README.md               # Complete documentation
├── DEPLOYMENT_GUIDE.md     # Step-by-step deployment
└── ARCHITECTURE.md         # Design patterns & best practices
```

## 🔐 Security Architecture

### Network Isolation
```
Internet
   ↓
ALB (Public Subnet)
   ↓
EKS Cluster (Private Subnet) ←→ Backend Servers (Private Subnet)
   ↓
NAT Gateway
   ↓
Outbound Internet (one-way)
```

### Access Control Matrix
| Source | Target | Method | Port |
|--------|--------|--------|------|
| Internet | ALB | HTTP | 80 |
| Internet | Bastion | SSH | 22 |
| Bastion | EKS Cluster | kubectl | 6443 |
| EKS Pods | Backend | TCP | 3306, 5432 |
| Bastion | Backend | SSH | 22 |

### Security Features
- ✅ VPC isolation
- ✅ Public/Private subnet segmentation
- ✅ Security group firewall rules
- ✅ IAM role-based access
- ✅ Kubernetes RBAC ready
- ✅ Private EKS endpoint (no public access)
- ✅ Bastion jump server requirement
- ✅ Database access restricted

## 📊 Resource Consumption

### Total Resources Deployed: ~50 AWS resources

| Category | Count |
|----------|-------|
| VPC Resources | 13 |
| Security Groups & Rules | 11 |
| IAM Resources | 8 |
| EKS Resources | 4 |
| Load Balancer Resources | 4 |
| EC2 Instances | 4 (Bastion + 2-4 EKS nodes + 2+ Backend) |
| Networking (EIPs, ENIs) | 6+ |

### Estimated Monthly Cost

| Component | Quantity | Monthly Cost |
|-----------|----------|--------------|
| EKS Control Plane | 1 | $73 |
| EC2 t2.medium (EKS nodes) | 2 | $60 |
| EC2 t3.small (Backend) | 2 | $30 |
| EC2 t3.micro (Bastion) | 1 | $8 |
| ALB | 1 | $22 |
| NAT Gateways | 2 | $64 |
| Data Transfer | - | $20 |
| **Total** | | **~$277** |

## 🚀 Quick Deployment

### Prerequisites
```bash
✓ AWS Account with appropriate IAM permissions
✓ Terraform 1.0+ installed
✓ AWS CLI configured
✓ EC2 Key Pair created
```

### Deployment Steps
```bash
# 1. Clone and navigate
cd 07-three-tier-app

# 2. Configure
vim terraform.tfvars
# Update: bastion_key_pair_name, bastion_allowed_cidr

# 3. Deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 4. Access
terraform output
```

**Deployment time**: 20-30 minutes

## 📡 Access Patterns

### Access Applications
```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Access application
curl http://$ALB_DNS
```

### Access EKS Cluster
```bash
# 1. SSH to Bastion
ssh -i my-key.pem ec2-user@<bastion-ip>

# 2. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name three-tier-app-eks

# 3. Manage cluster
kubectl get nodes
kubectl apply -f deployment.yaml
```

### Access Backend
```bash
# From Bastion
ssh -i my-key.pem ec2-user@<backend-private-ip>

# Or from EKS pod
kubectl run debug --image=amazonlinux:2 -it -- /bin/bash
# Then: curl http://<backend-ip>:3306
```

## ⚙️ Configuration Options

### Scale EKS
```hcl
eks_desired_size = 3       # Current: 2
eks_max_size = 6           # Current: 4
eks_instance_type = "t3.medium"  # Current: t2.medium
```

### Scale Backend
```hcl
backend_instance_count = 4  # Current: 2
backend_instance_type = "t3.medium"  # Current: t3.small
```

### Network Customization
```hcl
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
```

## 📋 Features Included

### Networking
- ✅ Multi-AZ VPC (3+ availability zones)
- ✅ Public subnets with IGW
- ✅ Private subnets with NAT Gateway
- ✅ Proper routing tables
- ✅ Network segmentation

### Compute
- ✅ EKS Cluster with managed nodes
- ✅ Auto-scaling node groups
- ✅ Backend EC2 servers
- ✅ Bastion jump host

### Load Balancing
- ✅ Application Load Balancer
- ✅ Target groups for EKS services
- ✅ Listener rules
- ✅ Health checks

### Security
- ✅ 5 security groups
- ✅ IAM roles for EKS & nodes
- ✅ OIDC provider for IRSA
- ✅ Encrypted communication ready
- ✅ Private endpoint configuration

### Logging & Monitoring
- ✅ EKS control plane logging enabled
- ✅ CloudWatch log groups
- ✅ ALB access logs ready
- ✅ VPC Flow Logs ready

## 🔄 Next Steps

1. **Deploy Ingress Controller**
   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system --set clusterName=three-tier-app-eks
   ```

2. **Deploy Sample Application**
   ```bash
   kubectl create deployment web --image=nginx
   kubectl expose deployment web --port=80 --type=LoadBalancer
   ```

3. **Setup Monitoring**
   - Install Prometheus & Grafana
   - Configure CloudWatch alarms
   - Setup log aggregation (ELK)

4. **Database Setup**
   - Launch RDS instances
   - Configure backups
   - Setup replication

5. **CI/CD Integration**
   - Deploy ArgoCD or Flux
   - GitOps workflow setup
   - Automated deployments

6. **Security Hardening**
   - Network policies
   - Pod security policies
   - RBAC configuration
   - Secret management

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **README.md** | Complete architecture & deployment guide |
| **DEPLOYMENT_GUIDE.md** | Step-by-step deployment instructions |
| **ARCHITECTURE.md** | Design patterns & best practices |
| **This File** | Project summary & quick reference |

## 🛠️ Customization

All components are fully customizable via `terraform.tfvars`:

```hcl
# Network
aws_region = "us-east-1"
vpc_cidr = "10.0.0.0/16"

# EKS
kubernetes_version = "1.34"
eks_desired_size = 2
eks_instance_type = "t2.medium"

# Backend
backend_instance_count = 2
backend_instance_type = "t3.small"

# Bastion
bastion_key_pair_name = "your-key"
bastion_allowed_cidr = ["YOUR_IP/32"]
```

## ⚡ Performance Tuning

### EKS Optimization
- Enhanced networking (ENA) enabled
- Proper security group rules
- Right-sized instances

### Database Optimization
- Connection pooling ready
- Backup strategy ready
- Read replica capable

### Network Optimization
- Multi-AZ load distribution
- NAT gateway for outbound traffic
- Optimized routing

## 🧹 Cleanup

```bash
# Destroy all resources
terraform destroy

# Or selective destruction
terraform destroy -target=module.backend_servers
terraform destroy -target=module.eks
```

## ✅ Production Readiness

- [x] Modular Terraform code
- [x] Multi-AZ deployment
- [x] Auto-scaling capability
- [x] Security best practices
- [x] Comprehensive documentation
- [x] Cost estimation included
- [x] Monitoring ready
- [x] Backup/recovery capable
- [x] HA architecture
- [x] Disaster recovery planning

## 📞 Support & Troubleshooting

See **DEPLOYMENT_GUIDE.md** for:
- Troubleshooting common issues
- AWS CLI commands
- Monitoring & debugging
- Cost management
- Performance tuning

## 📝 License

This Terraform configuration is provided as-is for educational and deployment purposes.

---

**Last Updated**: January 24, 2026  
**Terraform Version**: ~> 1.0  
**AWS Provider**: ~> 5.0  
**Kubernetes Version**: 1.34
