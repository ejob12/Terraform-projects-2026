# AWS Backup and Disaster Recovery Interview Notes

## 1. The interview summary

I designed the backup and disaster-recovery model around three principles: protect the data, rebuild the infrastructure, and regularly prove that recovery works.

Terraform provisions the repeatable control plane: AWS Backup vaults, KMS encryption keys, IAM permissions, backup plans, retention policies, cross-Region copy rules, and optional EC2 AMI creation. AWS Backup performs the scheduled backup jobs after those policies exist. Terraform also keeps the VPC, subnets, security groups, EKS configuration, EC2 definitions, and IAM configuration reproducible from version-controlled source.

The primary Region in this repository is `us-east-1` and the default DR Region is `us-west-2`. The Region choice is a design parameter, not a hard-coded recovery assumption.

A strong interview answer is:

> I separate infrastructure recovery from data recovery. Terraform can recreate the infrastructure, but it cannot replace application data. AWS Backup provides centrally managed recovery points with retention and cross-Region copies. AMIs provide a fast way to rebuild EC2 operating systems and installed software. EBS snapshots protect the underlying block-storage data. KMS protects the backups at rest. I select resources deliberately, restrict the backup IAM role, monitor job status, and test restores against the required RPO and RTO.

## 2. What the infrastructure contains

The backup-enabled stacks are:

- `03-vpc+compute`: public and private EC2 instances.
- `05-vpc-demo+compute+security-groups`: web and database EC2 instances.
- `06-eks-cluster`: an EKS cluster and managed worker node group.
- `07-three-tier-app`: an EKS cluster, backend EC2 instances, and a bastion host.

The backup Terraform creates an encrypted primary vault, an encrypted DR vault, KMS keys in both Regions, an AWS Backup service role, a daily backup plan, primary retention, and a cross-Region copy action. Resource selections target the EC2 instances or EKS cluster owned by each stack.

IAM-only and VPC-only stacks are not treated as data backup targets. Their desired state is kept in Git and they are recreated by Terraform. In a production environment I would still protect the Terraform state itself with an encrypted remote backend, state locking, restricted access, versioning, and a recovery process.

## 3. Customized Amazon Machine Images

An AMI is a reusable image template for launching an EC2 instance. It normally includes the operating system, installed packages, configuration files, and snapshots of the instance's attached EBS volumes.

In this repository, `ami-backup.tf` uses `aws_ami_from_instance` to create an image from each managed EC2 instance. It uses `snapshot_without_reboot = true`, which avoids interrupting the server but means the image may not be application-consistent. For a database or other write-heavy workload, I would quiesce the application, use a database-native backup, or use a coordinated snapshot process instead of assuming that a crash-consistent image is sufficient.

The optional AMI workflow then uses `aws_ami_copy` to copy and encrypt the image in the DR Region with the DR KMS key. During an incident, an operator can use the copied AMI to launch a replacement instance in the recovered VPC, subnets, and security groups.

### Why use a customized AMI?

- It shortens server rebuild time because the operating system and software are already installed.
- It standardizes server builds and reduces configuration drift.
- It preserves a known-good baseline for rollback.
- It can help meet an RTO that would be difficult to meet with a fresh operating-system install.
- It is useful for immutable infrastructure, where replacement is preferred over repairing a damaged server.

### AMI limitations and lifecycle concerns

An AMI is not a complete disaster-recovery system. It does not automatically preserve VPCs, subnets, route tables, security groups, IAM roles, load balancers, DNS, secrets, or external databases. It is also a point-in-time image, not a continuous backup. AMIs can contain sensitive data, so I encrypt them, control sharing permissions, and avoid baking long-lived credentials into the image.

AMI creation should have a lifecycle policy. Without expiration or controlled replacement, old AMIs and their EBS snapshots accumulate cost. In production I would use a naming/versioning convention, retention limits, tagging, vulnerability scanning, patching, and an automated cleanup process. I would also decide whether an AMI is created on demand, on a release, or on a scheduled cadence rather than creating a new image on every Terraform apply.

The AMI option is disabled by default in these stacks because image creation has cost and operational consequences. It is enabled deliberately when an EC2 workload needs this additional recovery path.

EKS managed worker nodes are different. EKS creates and manages the node-group Auto Scaling Group and node lifecycle. I would not create unmanaged AMIs for those workers as the primary recovery mechanism. I would restore the EKS control-plane data where supported, recreate the cluster infrastructure with Terraform, and let the managed node group launch supported worker images. Custom EKS node images are appropriate only when there is a documented need for custom kernel, security-agent, or OS configuration.

## 4. EBS snapshots

An EBS snapshot is a point-in-time backup of an EBS volume. AWS stores snapshots incrementally, so after the first snapshot, later snapshots generally store changed blocks rather than copying the entire volume again. This reduces storage consumption, although restore speed, snapshot size, and change rate still affect cost and recovery planning.

Snapshots are the storage foundation for several mechanisms in this design:

- AWS Backup creates and manages recovery points for supported EC2 and EBS resources.
- An AMI references snapshots for the instance's EBS-backed volumes.
- An AMI copy creates corresponding snapshots in the destination Region.
- A restored EC2 instance can be built from the recovery point or AMI.

Snapshots are crash-consistent unless the workload is paused or coordinated. For a database, filesystem buffers and transactions may not be in the desired state at the instant of capture. I would combine snapshots with database-native backups, transaction logs, application hooks, or AWS Backup application-consistent features where supported.

Snapshots are Region-specific by default. A snapshot in `us-east-1` does not automatically provide protection from a `us-east-1` regional outage. Cross-Region copy is therefore important for regional disaster recovery. Snapshot copies may also require KMS permissions and a compatible key policy in the destination Region.

## 5. AWS Backup service components

### Backup vaults

A backup vault is a logical container for recovery points. This configuration has one encrypted primary vault and one encrypted DR vault. Separate vaults make ownership, access, retention, monitoring, and regional recovery boundaries explicit.

For stronger production protection, I would evaluate AWS Backup Vault Lock. Vault Lock can enforce retention and help prevent even privileged users from deleting recovery points during a defined compliance period. I would use governance or compliance mode only after validating the retention and incident-response requirements because an incorrectly locked vault is intentionally difficult to change.

### Backup plans and rules

A backup plan defines when backups run, where recovery points are stored, the allowed start and completion windows, retention, and copy actions. The plans in this repository run daily in UTC, retain primary recovery points for the configured period, and copy them to the DR vault with a separate retention period.

The schedule is a policy, not the backup data itself. AWS Backup executes the jobs and records success or failure. I would monitor job status and alert on missed, expired, or failed jobs.

### Backup selections

A selection determines which resources a plan protects and which IAM role AWS Backup assumes. These stacks use explicit resource ARNs for the EC2 instances and EKS cluster. Explicit selection reduces accidental coverage gaps caused by inconsistent tags. In a larger environment, I might combine tag-based selection with explicit exceptions, provided the tagging standard is enforced.

### IAM service role

AWS Backup needs permission to create backups, copy recovery points, and restore resources. The Terraform configuration creates a role trusted by `backup.amazonaws.com` and attaches the AWS-managed backup and restore policies.

In a production review, I would use least privilege where practical, separate backup and restore operator permissions, restrict who can delete vaults or recovery points, and audit role use with CloudTrail. Restore permissions deserve particular care because a restore can create compute, storage, network, and data resources.

### KMS encryption

The primary and DR vaults use separate customer-managed KMS keys with rotation enabled. Encryption protects recovery points at rest and makes key ownership explicit. Cross-Region backup copies require the destination Region's key and the correct KMS key policy. A key deletion or permission failure can make an otherwise healthy backup unusable, so key access, rotation, recovery, and deletion protection belong in the DR plan.

### Cross-Region backup copies

The primary backup is created in `us-east-1` and copied to `us-west-2`. This addresses a regional failure that would make the primary vault unavailable. Cross-Region copy is not the same as cross-account isolation. For protection against an account compromise or destructive administrator action, I would also copy backups to a separate security or backup account with tightly controlled access.

### Supported AWS resource families

AWS Backup is a centralized service for supported AWS resources, including commonly used services such as EC2/EBS, EFS, RDS, DynamoDB, FSx, and EKS-related resources where supported by the current AWS service and Region. The exact feature set, application consistency, cross-Region behavior, and restore model vary by resource type, so I verify current AWS support before claiming coverage.

For this repository, the practical targets are EC2/EBS and EKS. A real three-tier application would normally add service-specific protection for its data layer, such as RDS automated backups and point-in-time recovery, S3 versioning and replication, or database-native replication. Backing up only the EC2 operating system would not be enough to recover a database correctly.

## 6. Data Lifecycle Manager and AWS Backup: when to use each

Amazon Data Lifecycle Manager, or DLM, is designed primarily to automate the lifecycle of EBS snapshots and EBS-backed AMIs using schedules and tags. It is a good fit for straightforward EC2 snapshot policies, such as hourly or daily snapshots with count-based retention.

AWS Backup is broader and more centralized. It provides backup plans, vaults, cross-Region and potentially cross-account copies, retention, restore workflows, audit integration, and support across multiple AWS resource families.

I would avoid creating overlapping DLM and AWS Backup policies for the same volumes unless there is a deliberate reason. Overlap can create duplicate recovery points, confusing ownership, extra cost, and unclear restore procedures. In this repository, AWS Backup is the implemented scheduled service. DLM is a valid alternative for a focused EBS/AMI lifecycle policy, but no DLM resource is currently provisioned.

## 7. Backup versus disaster recovery

Backup and disaster recovery are related but not identical.

- Backup is the process of creating recoverable copies of data.
- Disaster recovery is the complete capability to restore service, including infrastructure, data, identity, networking, application configuration, traffic routing, and operational procedures.

Terraform helps rebuild the VPC, subnets, route tables, security groups, load balancers, IAM resources, EKS configuration, and EC2 definitions. AWS Backup restores supported data and service resources. AMIs accelerate EC2 replacement. DNS, secrets, external dependencies, application deployment, and validation still need explicit recovery steps.

### RPO and RTO

Recovery Point Objective, or RPO, is the maximum acceptable amount of data loss measured in time. A daily backup schedule can imply up to roughly a day's backup gap, depending on the failure time and job completion. That may be acceptable for a development environment but not for a critical database.

Recovery Time Objective, or RTO, is the maximum acceptable time to restore service. Cross-Region copies, preplanned networking, tested Terraform, AMIs, and automated deployment reduce RTO. A backup that exists but has never been restored should not be treated as proven recovery capability.

## 8. How I would operate this in production

1. Classify each workload and define its RPO, RTO, retention, and compliance requirements.
2. Select the correct protection mechanism: AWS Backup, DLM, database-native backup, replication, or a combination.
3. Encrypt backups with customer-managed KMS keys and protect key policies and deletion controls.
4. Use separate primary, DR, and preferably security-account backup boundaries.
5. Apply tags and explicit resource selections so coverage is measurable.
6. Monitor backup, copy, and restore jobs with CloudWatch, EventBridge, AWS Backup Audit Manager, or an equivalent operational system.
7. Alert on missing resources, failed jobs, stale recovery points, and insufficient retention.
8. Test restores regularly into an isolated recovery environment.
9. Validate application behavior, database consistency, DNS, security controls, and monitoring after restore.
10. Record recovery evidence and update the runbook when the architecture changes.

## 9. Important limitations in this example

This repository demonstrates the Terraform control plane; it is not a complete production runbook. The default AMI option is disabled, DLM policies are not provisioned, Backup Vault Lock is not provisioned, and application-specific database or S3 protection is not included. The EKS worker node group is managed by EKS and its Auto Scaling Group should remain EKS-owned.

Before production use, I would add restore testing, alerting, backup compliance checks, application-consistent database protection, cross-account isolation, secret recovery, and a documented regional failover procedure. I would also confirm that each selected resource type and encryption mode is supported for both Regions at deployment time.

## 10. Interview closing statement

> My goal is not simply to create snapshots. My goal is to establish a tested recovery system. I use Terraform to make the backup policy and infrastructure reproducible, AWS Backup to manage scheduled recovery points, KMS to protect them, cross-Region copies to handle regional failure, and customized AMIs to accelerate EC2 rebuilds. I define RPO and RTO per workload, avoid overlapping lifecycle policies, protect the backup account and keys, monitor every job, and regularly perform restore tests so the organization knows the backups are usable.