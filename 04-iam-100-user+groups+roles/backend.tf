terraform {
  backend "s3" {
    bucket         = "2026-state"
    key            = "04-iam/terraform.tfstate"
    region         = "ca-central-1"
    # encrypt        = true
    # dynamodb_table = "terraform-locks"
  }
}
