# ===== IAM GROUP =====

# Create IAM Group
resource "aws_iam_group" "interns" {
  name = var.group_name
}

# ===== IAM POLICY FOR READ-ONLY ACCESS =====

# Attach AWS Managed ReadOnly Policy to the group
resource "aws_iam_group_policy_attachment" "readonly_policy" {
  group      = aws_iam_group.interns.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ===== IAM USERS (100 USERS) =====

# Create 100 IAM Users
resource "aws_iam_user" "interns" {
  count = var.user_count
  name  = "${var.user_name_prefix}-${format("%03d", count.index + 1)}"

  tags = {
    Name  = "${var.user_name_prefix}-${format("%03d", count.index + 1)}"
    Type  = "Intern"
    Batch = "2026"
  }
}

# ===== CONSOLE ACCESS FOR USERS =====

# Create login profiles for console access
# AWS generates a temporary password automatically
resource "aws_iam_user_login_profile" "interns" {
  count                   = var.enable_console_access ? var.user_count : 0
  user                    = aws_iam_user.interns[count.index].name
  password_reset_required = var.password_reset_required

  depends_on = [aws_iam_user.interns]
}

# ===== ADD USERS TO GROUP =====

# Add all users to the interns group
resource "aws_iam_user_group_membership" "interns" {
  count = var.user_count
  user  = aws_iam_user.interns[count.index].name

  groups = [
    aws_iam_group.interns.name
  ]

  depends_on = [aws_iam_group.interns]
}

# ===== CUSTOM POLICY FOR ADDITIONAL PERMISSIONS =====

# Create a custom policy for console users
resource "aws_iam_policy" "console_access_policy" {
  name        = "${var.group_name}-console-access"
  description = "Policy to allow console access with basic permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:ListMFADevices",
          "iam:ListSigningCertificates",
          "iam:ListSSHPublicKeys",
          "iam:ChangePassword"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetAccountSummary",
          "iam:ListVirtualMFADevices"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach custom console access policy to the group
resource "aws_iam_group_policy_attachment" "console_access_policy" {
  group      = aws_iam_group.interns.name
  policy_arn = aws_iam_policy.console_access_policy.arn
}
