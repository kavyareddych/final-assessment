provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  assume_role {
    role_arn = "arn:aws:iam::752378938230:role/Terraform-Admin-Role"
  }
}
resource "aws_vpc" "my-vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "my-devops-evaluation-vpc"
  }
}
resource "aws_internet_gateway" "my-igw-1" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "my-devops-evaluation-vpc-internet-gateway"
  }
}
resource "aws_route_table" "rt-table" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw-1.id
  }
  tags = {
    Name = "my-devops-evaluation-vpc-route-table"
  }
}
resource "aws_subnet" "pri-subnet" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false
  tags = {
    Name = "my-devops-evaluation-vpc-private-subnet"
  }
}
resource "aws_subnet" "pub-subnet" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "my-devops-evaluation-vpc-public-subnet"
  }
}
resource "aws_route_table_association" "my-rt-association" {
  subnet_id      = aws_subnet.pri-subnet.id
  route_table_id = aws_route_table.rt-table.id

}
resource "aws_security_group" "my-sg" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "my-devops-evaluation-vpc-security-group"
  }
  ingress {

    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_network_interface" "my-ni" {
  subnet_id       = aws_subnet.pri-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.my-sg.id]
}
resource "aws_eip" "name" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.my-ni.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.my-igw-1]
}
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
}
resource "aws_key_pair" "ec2_key" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_key.public_key_openssh
}
resource "aws_instance" "ec2_instance" {
  ami               = var.ami
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  key_name          = aws_key_pair.ec2_key.key_name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.my-ni.id
  }

  user_data                   = <<EOF
#!/bin/bash -xe
## Setup AWS SSM Agent
check_ssm_agent_installed=$(systemctl list-units --type=service | grep "amazon-ssm-agent" | awk '{print $2}')
check_ssm_agent_enabled=$(systemctl list-units --type=service | grep "amazon-ssm-agent" | awk '{print $3}')
check_ssm_agent_running=$(systemctl list-units --type=service | grep "amazon-ssm-agent" | awk '{print $4}')
if [ "$${check_ssm_agent_installed}" != "loaded" ]; then
  sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
elif [ "$${check_ssm_agent_enabled}" != "active" ]; then
  sudo systemctl enable amazon-ssm-agent
elif [ "$${check_ssm_agent_running}" != "running" ]; then
  sudo systemctl start amazon-ssm-agent
fi

## Setup Docker Engine
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo usermod -a -G docker ec2-user
sudo systemctl enable docker
sudo systemctl start docker
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo aws configure set aws_access_key_id ${var.access_key}
sudo aws configure set aws_secret_access_key ${var.secret_key} 
sudo aws ecr get-login-password --region ${var.region} | sudo docker login --username AWS --password-stdin 752378938230.dkr.ecr.us-east-1.amazonaws.com
sudo docker pull 752378938230.dkr.ecr.us-east-1.amazonaws.com/k8s-testing:latest
sudo docker run -d -p 8080:80 752378938230.dkr.ecr.us-east-1.amazonaws.com/k8s-testing:latest
EOF
  user_data_replace_on_change = true

  tags = {
    Name = "my-devops-evaluation-instance"
  }
}
