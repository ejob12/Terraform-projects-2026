provider "aws" {
  alias  = "backup_dr"
  region = var.backup_dr_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.app_name
      ManagedBy   = "Terraform"
      Purpose     = "Disaster recovery backups"
    }
  }
}

resource "aws_kms_key" "backup" {
  description             = "KMS key for ${var.app_name} AWS Backup vault"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "backup" {
  name          = "alias/${var.app_name}-backup"
  target_key_id = aws_kms_key.backup.key_id
}

resource "aws_kms_key" "backup_dr" {
  provider                = aws.backup_dr
  description             = "KMS key for ${var.app_name} DR backup vault"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "backup_dr" {
  provider      = aws.backup_dr
  name          = "alias/${var.app_name}-backup-dr"
  target_key_id = aws_kms_key.backup_dr.key_id
}

resource "aws_backup_vault" "primary" {
  name        = "${var.app_name}-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn
}

resource "aws_backup_vault" "dr" {
  provider    = aws.backup_dr
  name        = "${var.app_name}-dr-vault"
  kms_key_arn = aws_kms_key.backup_dr.arn
}

resource "aws_iam_role" "backup" {
  name = "${var.app_name}-backup-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
  ])

  role       = aws_iam_role.backup.name
  policy_arn = each.value
}

resource "aws_backup_plan" "primary" {
  name = "${var.app_name}-backup-plan"

  rule {
    rule_name         = "daily-application-backup"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = var.backup_schedule
    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = var.backup_retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn

      lifecycle {
        delete_after = var.backup_copy_retention_days
      }
    }
  }
}

resource "aws_backup_selection" "application" {
  name         = "${var.app_name}-application-selection"
  plan_id      = aws_backup_plan.primary.id
  iam_role_arn = aws_iam_role.backup.arn
  resources = concat(
    [module.eks.cluster_arn, module.bastion.bastion_instance_arn],
    module.backend_servers.backend_instance_arns,
  )
}
