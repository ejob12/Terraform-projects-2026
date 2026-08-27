# Three-Tier Application Architecture - Deployment Guide

## Quick Start

### Step 1: Create EC2 Key Pair

```bash
aws ec2 create-key-pair --key-name my-app-key \
  --region us-east-1 \
  --query 'KeyMaterial' --output text > my-app-key.pem

chmod 600 my-app-key.pem
```

### Step 2: Update Configuration

Edit `terraform.tfvars`:

```hcl
bastion_key_pair_name = "my-app-key"
bastion_allowed_cidr = ["YOUR_IP/32"]  # e.g., "203.0.113.42/32"
```

### Step 3: Deploy Infrastructure

```bash
cd 07-three-tier-app

# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

### Step 4: Get Access Information

```bash
# Display all outputs
terraform output

# Get specific values
BASTION_IP=$(terraform output -raw bastion_public_ip)
ALB_DNS=$(terraform output -raw alb_dns_name)
CLUSTER_NAME=$(terraform output -raw eks_cluster_id)

echo "Bastion: ssh -i my-app-key.pem ec2-user@$BASTION_IP"
echo "ALB: $ALB_DNS"
echo "Cluster: $CLUSTER_NAME"
```

## Architecture Components

### Tier 1: Public (Presentation)
- **Application Load Balancer**: Exposes applications to internet on port 80
- **Bastion Host**: SSH access for cluster management (t3.micro)
- **Security**: Restricted inbound rules

### Tier 2: Private (Application)  
- **EKS Cluster**: Kubernetes managed service
  - 2 worker nodes (t2.medium) by default
  - Auto-scaling from 1 to 4 nodes
  - Private endpoint (no public access)
- **Access**: Only via Bastion host using kubectl
- **Services**: Exposed through ALB

### Tier 3: Private (Data)
- **Backend Servers**: EC2 instances (t3.small)
  - Pre-installed with Docker and database clients
  - Number configurable (default: 2)
- **Databases**: MariaDB, PostgreSQL
- **Access**: From EKS pods or Bastion host only

## Access Patterns

### Access EKS Cluster from Bastion

```bash
# 1. SSH to bastion
ssh -i my-app-key.pem ec2-user@$BASTION_IP

# 2. On bastion, configure AWS credentials
aws configure
# Enter: Access Key, Secret Key, region (us-east-1)

# 3. Get kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name three-tier-app-eks

# 4. Verify access
kubectl get nodes
kubectl get pods -A
```

### Access Applications via ALB

```bash
# Use the ALB DNS name to access applications
curl http://$ALB_DNS

# Or deploy a sample app
kubectl create deployment web --image=nginx --port=80
kubectl expose deployment web --type=LoadBalancer --port=80 --target-port=80
```

### SSH to Backend Servers

```bash
# From bastion
ssh -i my-app-key.pem ec2-user@<backend-private-ip>

# Or through bastion jump
ssh -i my-app-key.pem \
  -J ec2-user@$BASTION_IP \
  ec2-user@<backend-private-ip>
```

## Networking Details

### Security Groups

1. **ALB Security Group**
   - Inbound: 80, 443 from 0.0.0.0/0
   - Outbound: All

2. **Bastion Security Group**
   - Inbound: 22 from allowed CIDR
   - Outbound: All

3. **EKS Cluster Security Group**
   - Inbound: 443 from nodes, 1025-65535 from ALB
   - Outbound: All

4. **EKS Nodes Security Group**
   - Inbound: 1025-65535 from cluster, all from ALB, self-referential
   - Outbound: All

5. **Backend Security Group**
   - Inbound: 3306 (MySQL), 5432 (PostgreSQL) from EKS nodes, 22 from bastion
   - Outbound: All

### Subnet Layout

```
VPC: 10.0.0.0/16
├── Public Subnets (2 - Multi-AZ)
│   ├── 10.0.1.0/24 (us-east-1a) - ALB, Bastion
│   └── 10.0.2.0/24 (us-east-1b) - ALB redundancy
├── Private Subnets (3)
│   ├── 10.0.11.0/24 (us-east-1a) - EKS, Backend
│   ├── 10.0.12.0/24 (us-east-1b) - EKS, Backend
│   └── 10.0.13.0/24 (us-east-1c) - EKS, Backend
└── NAT Gateways (2)
    ├── In 10.0.1.0/24 (route from 10.0.11.0/24)
    └── In 10.0.2.0/24 (route from 10.0.12.0/24)
```

## Customization Examples

### Increase EKS Cluster Size

```hcl
# In terraform.tfvars
eks_desired_size = 3
eks_max_size = 5
eks_instance_type = "t3.medium"  # Larger type
```

Then apply:
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

### Add More Backend Servers

```hcl
backend_instance_count = 4
backend_instance_type = "t3.medium"
```

### Add Third Public Subnet

```hcl
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
```

### Deploy Using Remote State

```hcl
# Uncomment in versions.tf
backend "s3" {
  bucket         = "my-terraform-state"
  key            = "three-tier/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

## Monitoring

### EKS Control Plane Logs

```bash
# View logs in CloudWatch
aws logs tail /aws/eks/three-tier-app-eks/cluster --follow

# Specific log streams
aws logs describe-log-groups \
  --query 'logGroups[?contains(logGroupName, `/eks/`)].logGroupName'
```

### Node Status

```bash
# From bastion
kubectl get nodes -o wide
kubectl top nodes
kubectl describe node <node-name>
```

### Pod Status

```bash
kubectl get pods -A
kubectl logs <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

### ALB Health

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region us-east-1
```

## Troubleshooting

### Cannot SSH to Bastion

```bash
# Check bastion is running
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=three-tier-app-bastion" \
  --region us-east-1

# Check security group allows your IP
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=three-tier-app-bastion-sg" \
  --region us-east-1
```

### EKS Nodes Not Ready

```bash
# Check nodes from cluster
kubectl get nodes
kubectl describe node <node-name>

# Check CloudWatch logs
aws logs tail /aws/eks/three-tier-app-eks/cluster

# Verify IAM roles
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=eks*" \
  --query 'Reservations[].Instances[].[IamInstanceProfile.Arn,State.Name]'
```

### ALB Not Routing Traffic

```bash
# Check target group
aws elbv2 describe-target-health \
  --target-group-arn <arn> \
  --region us-east-1

# Deploy ingress controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=three-tier-app-eks

# Create ingress resource
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
EOF
```

### Backend Servers Cannot Connect

```bash
# Check security group rules
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=three-tier-app-backend-sg" \
  --region us-east-1

# Test connectivity from EKS node
kubectl run debug --image=amazonlinux:2 -it -- /bin/bash
# Then: curl http://<backend-ip>:3306
```

## Cleanup

### Full Cleanup

```bash
terraform destroy
```

### Selective Cleanup

```bash
# Destroy specific component
terraform destroy -target=module.backend_servers

# Then destroy infrastructure in order:
# 1. backend_servers
# 2. eks
# 3. bastion
# 4. load_balancer
# 5. security_groups
# 6. vpc
```

## Next Steps

1. **Deploy Kubernetes Ingress Controller**: Use ALB ingress controller
2. **Enable Monitoring**: Install Prometheus, Grafana, ELK stack
3. **Add Service Mesh**: Deploy Istio or Linkerd
4. **Implement CI/CD**: Connect GitOps pipeline (ArgoCD, Flux)
5. **Database Setup**: Create RDS instances for backend
6. **Backup & Recovery**: Configure EBS snapshots, etcd backup
7. **Security Hardening**: Implement network policies, pod security policies

## Support Files

- `README.md` - Complete documentation
- `terraform.tfvars` - Configuration values
- `main.tf` - Resource definitions
- `outputs.tf` - Output values
- `versions.tf` - Provider configuration
- `modules/` - Modular components

## Cost Management

Monitor costs:
```bash
# Estimate monthly spend
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost"
```

Set budget alerts:
```bash
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account) \
  --budget BudgetName=three-tier-app,BudgetLimit=500
```
