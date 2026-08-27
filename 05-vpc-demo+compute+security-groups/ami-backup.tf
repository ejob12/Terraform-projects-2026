locals {
  ami_source_instances = {
    for instance in concat(aws_instance.web, aws_instance.db) : instance.id => instance
  }
}

resource "aws_ami_from_instance" "ec2" {
  for_each = var.enable_ami_backups ? local.ami_source_instances : {}

  name                    = "${var.ami_name_prefix}-${each.key}"
  source_instance_id      = each.value.id
  snapshot_without_reboot = true

  tags = {
    Name       = "${var.ami_name_prefix}-${each.key}"
    BackupType = "AMI"
    DRRegion   = var.backup_dr_region
  }
}

resource "aws_ami_copy" "ec2_dr" {
  for_each = aws_ami_from_instance.ec2
  provider = aws.backup_dr

  name              = "${each.value.name}-dr"
  source_ami_id     = each.value.id
  source_ami_region = var.aws_region
  encrypted         = true
  kms_key_id        = aws_kms_key.backup_dr.arn

  tags = {
    Name       = "${each.value.name}-dr"
    BackupType = "AMI"
    SourceAMI  = each.value.id
  }
}