terraform {
  backend "s3" {
    bucket = "2026-state-github"
    key    = "04-iam/terraform.tfstate"
    region = "us-east-1"
    # encrypt        = true
    # dynamodb_table = "terraform-locks"
  }
}
