# Terraform AWS Backup and Disaster Recovery

This repository contains independent Terraform stacks for AWS infrastructure. Backup and disaster-recovery resources are included only in stacks that provision backupable compute or application resources.

For an interview-ready explanation of the design, see [AWS_BACKUP_DR_INTERVIEW_NOTES.md](AWS_BACKUP_DR_INTERVIEW_NOTES.md).

## Backup-enabled folders

### `03-vpc+compute`

Protects the public and private EC2 instances with an encrypted AWS Backup vault, daily backup plan, retention policy, and cross-Region copy to a DR vault.

### `05-vpc-demo+compute+security-groups`

Protects the web and database EC2 instances with the same encrypted daily backup and cross-Region DR design.

### `06-eks-cluster`

Protects the EKS cluster resource through AWS Backup. The Terraform-managed VPC, IAM, and security-group resources remain reproducible from source control and Terraform state.

### `07-three-tier-app`

Protects the EKS cluster, backend EC2 instances, and bastion host. The load balancer and network resources are recreated by Terraform during recovery.

## Folders without AWS Backup resources

`00-compute` and `04-iam-100-user+groups+roles` manage IAM resources, which are policy and identity definitions rather than backup data sources. `02-vpc-networking` manages only network resources, which are recreated from Terraform configuration. These folders are still covered by Git history and protected Terraform state.

## What each backup configuration creates

- An AWS Backup vault in the workload Region.
- A separate encrypted vault and KMS key in the DR Region.
- A KMS key with rotation enabled for each vault.
- An IAM service role with AWS Backup backup and restore permissions.
- A daily scheduled backup plan.
- Primary recovery-point retention controlled by `backup_retention_days`.
- Cross-Region recovery-point retention controlled by `backup_copy_retention_days`.
- Resource selections for the EC2 instances or EKS cluster owned by that stack.

## AMI-based recovery

The EC2-backed stacks also contain `ami-backup.tf`. When `enable_ami_backups` is enabled, Terraform creates a point-in-time AMI from each managed EC2 instance and copies the AMI, encrypted with the DR KMS key, into the configured DR Region. The AMI name prefix is controlled by `ami_name_prefix`.

AMI creation captures the operating system, installed packages, and attached EBS volume contents at the image time. It does not provide continuous protection, application-consistent database backups, or automatic scheduled image rotation. AWS Backup remains the scheduled recovery-point mechanism; AMIs are an additional instance-rebuild mechanism. AMIs also do not preserve VPCs, subnets, security groups, IAM roles, load balancers, or DNS, so those resources must be recreated from Terraform during recovery.

The EKS-only stack does not create an AMI configuration because its worker nodes are managed by the EKS node group and use AWS-managed node images. EKS cluster recovery is handled through AWS Backup and recreation of the supporting Terraform-managed infrastructure rather than importing unmanaged worker-node AMIs.

## Recovery design

AWS Backup and Data Lifecycle Manager perform the scheduled backup operations after Terraform provisions the policies and vaults. Terraform manages the durable recovery configuration, while Git stores the infrastructure definition. Terraform state should be kept in an encrypted remote backend with state locking and restricted access.

The primary Region defaults to `us-east-1`. The DR Region defaults to `us-west-2` and can be changed with `backup_dr_region`. The daily schedule is UTC and can be changed with `backup_schedule`.

The network, IAM, security groups, load balancer, and EKS supporting infrastructure are reconstructed from the corresponding Terraform stack during a regional recovery. Application data that lives outside the selected EC2 volumes or EKS resources requires an application-specific backup strategy, such as Amazon RDS automated backups, S3 versioning and replication, or a database-native replication design.

## Important AWS prerequisites

The AWS account must support AWS Backup for the selected resource types in both Regions. The deployment identity needs permission to create KMS keys, AWS Backup vaults and plans, IAM roles and attachments, and cross-Region backup copies. The destination Region must be enabled for the account, and the selected resources must be supported by AWS Backup in that Region.