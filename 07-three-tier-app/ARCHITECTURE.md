# Architecture Best Practices & Reference

## Three-Tier Architecture Pattern

### Tier 1: Presentation Layer (Public)
**Purpose**: Handle internet-facing traffic and cluster access

**Components**:
- Application Load Balancer (ALB)
- Bastion Host (SSH Jump Server)

**Key Features**:
- Auto-scaling load balancing
- SSL/TLS termination (configurable)
- Web Application Firewall (WAF) ready
- DDoS protection via AWS Shield Standard

**Scaling**: Horizontal scaling via ALB target groups

### Tier 2: Application Layer (Private)
**Purpose**: Run containerized applications with Kubernetes

**Components**:
- EKS Cluster (Managed Kubernetes)
- Worker Nodes (EC2 instances)
- Service Discovery
- Container Registry (ECR)

**Key Features**:
- Managed control plane (no maintenance)
- Auto-scaling node groups
- Network isolation via VPC
- Service mesh ready (Istio, Linkerd)

**Scaling**: 
- Horizontal: Kubernetes HPA (Horizontal Pod Autoscaler)
- Vertical: EKS Managed Node Groups with auto-scaling
- Both: Combined auto-scaling strategy

### Tier 3: Data Layer (Private)
**Purpose**: Store and manage application data

**Components**:
- Backend Servers (EC2 instances)
- Relational Databases (MariaDB, PostgreSQL)
- Cache Layer (Redis, Memcached)
- Backup & Recovery

**Key Features**:
- Private subnet isolation
- Database replication across AZs
- Automated backups
- Point-in-time recovery

**Scaling**: 
- Vertical: Larger instance types
- Horizontal: Read replicas, sharding
- Both: Database clustering

## Network Architecture

### Data Flow Diagram

```
    ┌─────────────────────────────────────────────────────┐
    │                  INTERNET                            │
    │              (0.0.0.0/0)                            │
    └────────────────────┬────────────────────────────────┘
                         │
                         ▼
    ┌─────────────────────────────────────────────────────┐
    │           ROUTE 53 / DNS                             │
    │    (3-tier-app.example.com → ALB)                   │
    └────────────────────┬────────────────────────────────┘
                         │
                         ▼
    ┌─────────────────────────────────────────────────────┐
    │     AWS SHIELD STANDARD / WAF                        │
    │     (DDoS Protection)                                │
    └────────────────────┬────────────────────────────────┘
                         │
                         ▼
    ┌─────────────────────────────────────────────────────┐
    │  PUBLIC TIER - Security Group: ALB-SG               │
    │  ┌───────────────────────────────────────────────┐  │
    │  │  Application Load Balancer                    │  │
    │  │  ├─ Port 80 (HTTP)                            │  │
    │  │  └─ Port 443 (HTTPS)                          │  │
    │  │  [Multi-AZ across 2 subnets]                  │  │
    │  └───────────────────────────────────────────────┘  │
    │           │                          │               │
    │        80/443 ┌─────────────────┐ 80/443             │
    │           └──→│ Target Group    │←───┘              │
    │              │ (IP: Pods)       │                    │
    │              └─────────────────┘                     │
    │                                                       │
    │  ┌───────────────────────────────────────────────┐  │
    │  │ Bastion Host (t3.micro)                       │  │
    │  │ ├─ SSH Port 22 (from BASTION_ALLOWED_CIDR)   │  │
    │  │ └─ All outbound traffic                       │  │
    │  │ [Single Subnet - HA not recommended]          │  │
    │  └───────────────────────────────────────────────┘  │
    │           │                                           │
    │      SSH  └─────────┐                                │
    │                     │                                 │
    └─────────────────────┼─────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │   NAT    │    │   NAT    │    │   NAT    │
    │ Gateway  │    │ Gateway  │    │ Gateway  │
    │   10.0.1 │    │   10.0.2 │    │ (future) │
    └────┬─────┘    └────┬─────┘    └──────────┘
         │               │
         │               │
         ▼               ▼
    ┌───────────────────────────────────────────────────┐
    │  PRIVATE TIER - Security Group: EKS-Nodes-SG      │
    │                                                    │
    │  ┌──────────────────────────────────────────────┐ │
    │  │ EKS Cluster Control Plane (Managed)          │ │
    │  │ └─ PRIVATE Endpoint (No Public Access)       │ │
    │  │    (Accessible only via EKS API within VPC) │ │
    │  └──────────────────────────────────────────────┘ │
    │                                                    │
    │  ┌──────────────────────────────────────────────┐ │
    │  │ Worker Nodes (2-4 t2.medium instances)       │ │
    │  │ ├─ Security Group: EKS-Nodes-SG              │ │
    │  │ ├─ Private IPs across 3 AZs                  │ │
    │  │ └─ Auto-Scaling Group (1-4 nodes)            │ │
    │  │                                              │ │
    │  │ Node 1 (10.0.11.0/24):                      │ │
    │  │ ├─ Kubelet, Container Runtime               │ │
    │  │ └─ Pods running application workloads        │ │
    │  │                                              │ │
    │  │ Node 2 (10.0.12.0/24):                      │ │
    │  │ ├─ Kubelet, Container Runtime               │ │
    │  │ └─ Pods running application workloads        │ │
    │  │                                              │ │
    │  │ Node N (10.0.13.0/24):                      │ │
    │  │ ├─ Kubelet, Container Runtime               │ │
    │  │ └─ Pods running application workloads        │ │
    │  └──────────────────────────────────────────────┘ │
    │                     │                              │
    │          Port 3306/5432                           │
    │                     ▼                              │
    │  ┌──────────────────────────────────────────────┐ │
    │  │ Backend Tier - Security Group: Backend-SG    │ │
    │  │                                              │ │
    │  │ Backend Server 1 (10.0.11.x)                │ │
    │  │ ├─ MariaDB Master                           │ │
    │  │ └─ SSH 22 (from Bastion)                    │ │
    │  │                                              │ │
    │  │ Backend Server 2 (10.0.12.x)                │ │
    │  │ ├─ PostgreSQL Instance                      │ │
    │  │ └─ SSH 22 (from Bastion)                    │ │
    │  │                                              │ │
    │  │ Additional Servers (Configurable):          │ │
    │  │ ├─ Redis Cache                              │ │
    │  │ ├─ Memcached                                │ │
    │  │ └─ Message Queue (RabbitMQ, Kafka)          │ │
    │  └──────────────────────────────────────────────┘ │
    │                                                    │
    │  (All private, no direct internet access)         │
    │  (Outbound: via NAT Gateway to internet)          │
    └────────────────────────────────────────────────────┘
```

## Security Layers

### Layer 1: Network Security
- **VPC**: Isolated network space
- **Subnets**: Public/Private segmentation
- **Security Groups**: Instance-level firewall
- **Network ACLs**: Subnet-level filtering (optional)
- **Route Tables**: Traffic direction control

### Layer 2: Access Control
- **IAM Roles**: Service permissions
- **Instance Profiles**: EC2 to AWS service access
- **RBAC**: Kubernetes role-based access
- **Bastion Host**: SSH jump server for cluster access
- **Network Policies**: Pod-to-pod communication rules

### Layer 3: Encryption
- **In Transit**:
  - TLS/SSL for ALB
  - Encrypted EBS volumes
  - Encrypted data between pods
- **At Rest**:
  - EBS encryption
  - Database encryption
  - S3 bucket encryption

### Layer 4: Logging & Monitoring
- **CloudWatch**: Container logs
- **CloudTrail**: AWS API logging
- **Application Logs**: Pod/Container logs
- **ALB Logs**: HTTP request logging
- **VPC Flow Logs**: Network traffic analysis

## High Availability (HA) Design

### Regional Redundancy
```
us-east-1a
├─ Public Subnet 1
│  ├─ ALB Instance 1
│  └─ NAT Gateway 1
├─ Private Subnet 1
│  ├─ EKS Node 1
│  └─ Backend Server 1

us-east-1b
├─ Public Subnet 2
│  ├─ ALB Instance 2
│  └─ NAT Gateway 2
├─ Private Subnet 2
│  ├─ EKS Node 2
│  └─ Backend Server 2

us-east-1c (optional)
├─ Private Subnet 3
│  ├─ EKS Node 3
│  └─ Backend Server 3
```

### Load Balancing
- **ALB Cross-AZ**: Distributes traffic across AZs
- **Kubernetes Pod Spreading**: Pods distributed across nodes
- **Database Replication**: Master-Slave across AZs

### Failover Behavior
- **ALB Failure**: Traffic reroutes to healthy targets
- **Node Failure**: Pods reschedule to healthy nodes
- **AZ Failure**: Traffic shifts to other AZs
- **Database Failure**: Failover to replica (if configured)

## Auto-Scaling Strategy

### Horizontal Pod Autoscaler (HPA)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Cluster Autoscaler
```bash
# Install Cluster Autoscaler
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --set autoDiscovery.clusterName=three-tier-app-eks \
  --set awsRegion=us-east-1
```

### Combined Scaling Flow
```
High Load
   │
   ▼
Pod Metrics (CPU/Memory) exceed threshold
   │
   ▼
HPA triggers: Creates new Pod replicas
   │
   ▼
Node Capacity Full?
   │
   ├─ No → New pod scheduled on available node
   │
   └─ Yes → Cluster Autoscaler triggers
             │
             ▼
          ASG scales: Adds new EC2 instance
             │
             ▼
          New pod scheduled on new node
```

## Disaster Recovery

### Backup Strategy
1. **EBS Snapshots**: Automated daily snapshots
2. **Database Backups**: Automated daily, point-in-time recovery
3. **Kubernetes Manifests**: Version control (git)
4. **Configuration**: Terraform state backup (S3)
5. **Application Data**: Persistent volumes backup

### Recovery Procedures

#### Database Disaster Recovery
```bash
# From bastion, restore database
mysql -h backend-server-1 -u admin -p < backup.sql

# Or use AWS RDS with automated backups
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-db \
  --db-snapshot-identifier snapshot-arn
```

#### Cluster Recovery
```bash
# Redeploy cluster
terraform destroy -target=module.eks
terraform apply -target=module.eks

# Reapply applications
kubectl apply -f applications/
```

## Cost Optimization

### Reserved Instances
```bash
# Purchase Reserved Instances for baseline load
aws ec2 purchase-reserved-instances-offering \
  --instance-count 2 \
  --offering-id <offering-id>
```

### Spot Instances (Non-critical workloads)
```hcl
# Update launch template for Spot instances
capacity_type = "SPOT"  # In EKS node group
```

### Right-Sizing
```bash
# Analyze instance usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization
```

## Monitoring & Observability

### Key Metrics to Monitor

#### Infrastructure Metrics
- ALB: Request count, latency, target health
- EKS Nodes: CPU, memory, disk usage
- EC2 Instances: Network I/O, disk activity
- NAT Gateway: Bytes processed, connection count

#### Application Metrics
- Pod CPU/Memory utilization
- Request latency (p50, p95, p99)
- Error rate
- Throughput (requests/second)

#### Business Metrics
- Availability (uptime %)
- User response time
- API success rate
- Feature usage

### Recommended Monitoring Stack
1. **Prometheus**: Metrics collection
2. **Grafana**: Visualization dashboards
3. **CloudWatch**: AWS service metrics
4. **ELK Stack**: Log aggregation
5. **Jaeger**: Distributed tracing

## Production Checklist

- [ ] SSL/TLS certificates for ALB
- [ ] Network policies for pod isolation
- [ ] Pod security policies / Pod security standards
- [ ] Resource limits on pods
- [ ] Health checks (readiness, liveness probes)
- [ ] Persistent volume for stateful apps
- [ ] Database backups configured
- [ ] Monitoring and alerting enabled
- [ ] Logging aggregation setup
- [ ] Bastion SSH key rotation policy
- [ ] Security group audit
- [ ] IAM role least privilege review
- [ ] Backup and recovery tested
- [ ] Documentation complete
- [ ] Runbooks for common issues
- [ ] On-call escalation process

## Performance Optimization

### Network Performance
- Enable Enhanced Networking (ENA)
- Use latest generation instances (t3 vs t2)
- Optimize security group rules
- Consider placement groups for tight coupling

### Storage Performance
- Use GP3 EBS volumes for best price/performance
- Enable EBS optimization on instances
- Configure disk scheduling appropriately

### Application Performance
- Implement caching layer (Redis)
- Database query optimization
- Connection pooling
- CDN for static content
- Compression for HTTP responses

## References & Resources

### AWS Documentation
- https://docs.aws.amazon.com/eks/
- https://docs.aws.amazon.com/vpc/
- https://docs.aws.amazon.com/elasticloadbalancing/

### Kubernetes Documentation
- https://kubernetes.io/docs/
- https://kubernetes.io/docs/tasks/administer-cluster/
- https://kubernetes.io/docs/reference/

### Terraform Modules
- https://registry.terraform.io/modules/terraform-aws-modules/

### Best Practices
- https://aws.amazon.com/architecture/
- https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/
- https://12factor.net/
