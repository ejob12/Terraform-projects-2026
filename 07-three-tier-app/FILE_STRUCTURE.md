# Project File Structure

## Root Configuration Files

```
07-three-tier-app/
├── main.tf                  # Root module - Orchestrates all modules
├── variables.tf             # Input variables (20+ variables)
├── outputs.tf               # Output values (15+ outputs)
├── versions.tf              # Provider & backend configuration
├── terraform.tfvars         # Variable values (EDIT THIS!)
└── .gitignore              # Git ignore patterns
```

## Documentation Files

```
├── README.md                # Main documentation (comprehensive)
├── SUMMARY.md               # Project summary & quick reference
├── DEPLOYMENT_GUIDE.md      # Step-by-step deployment instructions
├── ARCHITECTURE.md          # Architecture patterns & best practices
└── FILE_STRUCTURE.md        # This file
```

## Module Files

```
modules/
├── vpc/
│   ├── main.tf              # VPC, subnets, NAT, routing (13 resources)
│   ├── variables.tf         # VPC input variables
│   └── outputs.tf           # VPC outputs
│
├── security-groups/
│   ├── main.tf              # 5 security groups + rules (11 resources)
│   ├── variables.tf         # Security group variables
│   └── outputs.tf           # Security group outputs
│
├── iam/
│   ├── main.tf              # IAM roles, policies, profiles (8 resources)
│   ├── variables.tf         # IAM variables
│   └── outputs.tf           # IAM outputs
│
├── bastion/
│   ├── main.tf              # Bastion host + EIP (3 resources)
│   ├── variables.tf         # Bastion variables
│   ├── outputs.tf           # Bastion outputs
│   └── user_data.sh         # Bastion initialization script
│
├── load-balancer/
│   ├── main.tf              # ALB + target group + listener (4 resources)
│   ├── variables.tf         # ALB variables
│   └── outputs.tf           # ALB outputs
│
├── eks/
│   ├── main.tf              # EKS cluster + node group + OIDC (4 resources)
│   ├── variables.tf         # EKS variables
│   └── outputs.tf           # EKS outputs
│
└── backend-servers/
    ├── main.tf              # EC2 instances (2+ resources)
    ├── variables.tf         # Backend variables
    ├── outputs.tf           # Backend outputs
    └── user_data.sh         # Backend initialization script
```

## Total Files Summary

| Category | Files | Details |
|----------|-------|---------|
| Root Config | 5 | terraform.tf, variables.tf, outputs.tf, versions.tf, tfvars |
| Documentation | 5 | README, SUMMARY, DEPLOYMENT_GUIDE, ARCHITECTURE, this file |
| Modules | 7 | vpc, security-groups, iam, bastion, load-balancer, eks, backend-servers |
| Module Files | 25 | 7 modules × (main.tf + variables.tf + outputs.tf) + 2 user_data scripts |
| **Total** | **40+** | Complete three-tier architecture |

## File Purposes

### Configuration Files

**main.tf**
- Orchestrates all modules
- Calls each module with appropriate inputs
- Establishes resource dependencies

**variables.tf**
- Defines input variables (20+)
- Includes default values
- Provides variable descriptions

**outputs.tf**
- Defines output values
- Critical for retrieving deployment info
- Used for accessing ALB, EKS, Bastion, etc.

**versions.tf**
- Terraform version requirement
- AWS provider configuration
- TLS provider setup
- Optional S3 backend configuration

**terraform.tfvars**
- Actual variable values
- **MUST BE EDITED before deployment**
- Contains AWS region, network CIDR, EC2 key pair name
- Security settings (bastion access CIDR)

### Documentation Files

**README.md**
- Complete architecture overview
- All configuration details
- Deployment steps
- Post-deployment setup
- Monitoring & troubleshooting
- References & resources

**SUMMARY.md**
- Quick reference
- Project overview
- Component details
- Quick deployment checklist
- Configuration options
- Next steps

**DEPLOYMENT_GUIDE.md**
- Step-by-step instructions
- Architecture components
- Access patterns
- Customization examples
- Monitoring commands
- Troubleshooting guide
- Cleanup procedures

**ARCHITECTURE.md**
- Design patterns
- Network architecture diagrams
- Security layers
- HA design
- Auto-scaling strategy
- Disaster recovery
- Cost optimization
- Monitoring & observability
- Production checklist

### Module Files

Each module contains:

**main.tf**
- Resource definitions
- Data sources
- Local values

**variables.tf**
- Input variables
- Default values
- Variable descriptions

**outputs.tf**
- Output values
- Used by parent modules
- Critical information exposure

### Special Files

**user_data.sh** (in bastion & backend-servers modules)
- Initialization scripts
- Package installation
- Service configuration
- Pre-deployment setup

## Key Files to Edit

### Before First Deployment

1. **terraform.tfvars** - REQUIRED
   ```hcl
   bastion_key_pair_name = "your-ec2-keypair-name"
   bastion_allowed_cidr = ["YOUR.IP.ADDRESS/32"]
   ```

### For Customization

2. **variables.tf** (root level)
   - Change default values if desired

3. **terraform.tfvars**
   - Customize instance types
   - Adjust scaling parameters
   - Modify network CIDR blocks

### Module-Specific Configuration

4. **modules/*/variables.tf**
   - Adjust module-level defaults (optional)
   - Usually not needed

## File Dependencies

```
terraform.tfvars
    ↓
variables.tf (root)
    ↓
main.tf (root)
    ├─ → modules/vpc/main.tf
    ├─ → modules/security-groups/main.tf
    ├─ → modules/iam/main.tf
    ├─ → modules/bastion/main.tf
    ├─ → modules/load-balancer/main.tf
    ├─ → modules/eks/main.tf
    └─ → modules/backend-servers/main.tf
    ↓
outputs.tf (root)
    ├─ → modules/vpc/outputs.tf
    ├─ → modules/security-groups/outputs.tf
    ├─ → modules/iam/outputs.tf
    ├─ → modules/bastion/outputs.tf
    ├─ → modules/load-balancer/outputs.tf
    ├─ → modules/eks/outputs.tf
    └─ → modules/backend-servers/outputs.tf
```

## Resource Count by Module

| Module | Resources | Key Resource Types |
|--------|-----------|-------------------|
| vpc | 13 | VPC, Subnets, IGW, NAT, Route Tables |
| security-groups | 11 | Security Groups, Ingress/Egress Rules |
| iam | 8 | IAM Roles, Policy Attachments, Instance Profiles |
| bastion | 3 | EC2 Instance, EIP, AMI Data Source |
| load-balancer | 4 | ALB, Target Group, Listener, Listener Rule |
| eks | 4 | EKS Cluster, Node Group, OIDC, TLS Cert |
| backend-servers | 2+ | EC2 Instances (configurable) |
| **Total** | **45+** | Complete three-tier architecture |

## Git Repository Structure

```
.gitignore
├── .terraform/
├── .terraform.lock.hcl
├── terraform.tfstate
├── terraform.tfstate.backup
├── *.tfvars          (typically excluded)
└── Tracked Files:
    ├── *.tf (all)
    ├── *.md (all)
    ├── .gitignore
    └── user_data.sh scripts
```

## Deployment Workflow

```
1. Edit terraform.tfvars
   └─ Set EC2 key pair name
   └─ Set allowed SSH CIDR

2. terraform init
   └─ Downloads provider plugins
   └─ Initializes working directory

3. terraform validate
   └─ Validates configuration syntax

4. terraform plan
   └─ Shows all resources to create

5. terraform apply
   └─ Creates all resources (20-30 min)

6. terraform output
   └─ Displays critical information

7. Post-deployment setup
   └─ Configure kubectl via bastion
   └─ Deploy applications
   └─ Setup monitoring
```

## Quick Reference Paths

```
Project Root:           07-three-tier-app/
Root Config:            07-three-tier-app/*.tf
Documentation:          07-three-tier-app/*.md
VPC Module:             07-three-tier-app/modules/vpc/
Security Groups:        07-three-tier-app/modules/security-groups/
IAM:                    07-three-tier-app/modules/iam/
Bastion:                07-three-tier-app/modules/bastion/
Load Balancer:          07-three-tier-app/modules/load-balancer/
EKS:                    07-three-tier-app/modules/eks/
Backend:                07-three-tier-app/modules/backend-servers/
Bastion Init:           07-three-tier-app/modules/bastion/user_data.sh
Backend Init:           07-three-tier-app/modules/backend-servers/user_data.sh
```

## Important Notes

1. **terraform.tfvars** should never be committed to git (add to .gitignore)
2. **terraform.tfstate** contains sensitive information (exclude from git)
3. Each module is self-contained and reusable
4. All modules follow Terraform best practices
5. Documentation is comprehensive and kept up-to-date
6. Architecture is production-ready with HA and auto-scaling

---

**Total Project Size**: ~40 files, ~3000+ lines of Terraform code, ~2000+ lines of documentation
**Deployment Time**: 20-30 minutes
**Estimated Resources**: 45+ AWS resources
**Estimated Monthly Cost**: $270-290
