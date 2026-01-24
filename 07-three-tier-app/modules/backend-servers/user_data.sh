#!/bin/bash
set -e

# Update system packages
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install MariaDB client
yum install -y mariadb

# Install PostgreSQL client
yum install -y postgresql

# Install monitoring tools
yum install -y cloudwatch-agent

# Create app directory
mkdir -p /opt/${app_name}

# Log that server is ready
echo "Backend server for ${app_name} is ready" > /opt/${app_name}/status.txt
