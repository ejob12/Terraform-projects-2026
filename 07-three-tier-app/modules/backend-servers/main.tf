# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Backend Servers
resource "aws_instance" "backend" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.security_group_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_name = var.app_name
  }))

  tags = {
    Name = "${var.app_name}-backend-${count.index + 1}"
  }
}
