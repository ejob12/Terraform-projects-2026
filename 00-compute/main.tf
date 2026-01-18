# Create IAM User
resource "aws_iam_user" "prof_prince" {
  name = var.iam_user_name

  tags = {
    Name = var.iam_user_name
  }
}

# Create IAM Group
resource "aws_iam_group" "admin_group" {
  name = var.iam_group_name
}

# Add user to group
resource "aws_iam_user_group_membership" "prof_prince_group_membership" {
  user = aws_iam_user.prof_prince.name

  groups = [
    aws_iam_group.admin_group.name
  ]
}

# Create policy for compute full access
resource "aws_iam_policy" "compute_full_access" {
  name        = "${var.iam_group_name}-compute-full-access"
  description = "Full access to EC2, ECS, EKS, and related compute services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecs:*",
          "eks:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "logs:*",
          "sns:*",
          "sqs:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to group
resource "aws_iam_group_policy_attachment" "admin_compute_access" {
  group      = aws_iam_group.admin_group.name
  policy_arn = aws_iam_policy.compute_full_access.arn
}
