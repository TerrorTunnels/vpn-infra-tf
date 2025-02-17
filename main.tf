provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region to deploy the VPN"
  default     = "us-west-2"
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instance admin"
  default     = "your-ssh-key-name"
}

resource "aws_vpc" "vpn_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "vpn_igw" {
  vpc_id = aws_vpc.vpn_vpc.id
}

resource "aws_route_table" "vpn_rt" {
  vpc_id = aws_vpc.vpn_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpn_igw.id
  }
}

resource "aws_route_table_association" "vpn_rta" {
  subnet_id      = aws_subnet.vpn_subnet.id
  route_table_id = aws_route_table.vpn_rt.id
}
resource "aws_subnet" "vpn_subnet" {
  vpc_id                  = aws_vpc.vpn_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "vpn_sg" {
  vpc_id = aws_vpc.vpn_vpc.id

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "vpn_instance" {
  # ami subject to change based on region, please check the latest ami id for your deployment region
  ami                    = "ami-0b16505c55f9802f9" # Amazon Linux 2 arm64 - us-west-2
  instance_type          = "t4g.micro"
  subnet_id             = aws_subnet.vpn_subnet.id
  vpc_security_group_ids = [aws_security_group.vpn_sg.id]
  associate_public_ip_address = true
  key_name               = var.ssh_key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras enable epel
              yum install -y openvpn easy-rsa
              curl -O https://raw.githubusercontent.com/Angristan/OpenVPN-install/master/openvpn-install.sh
              chmod +x openvpn-install.sh
              AUTO_INSTALL=y ./openvpn-install.sh
              EOF

  tags = {
    Name = "VPN-Instance"
  }
}

resource "aws_eip" "vpn_eip" {
  instance = aws_instance.vpn_instance.id
}

output "vpn_ip" {
  value = aws_eip.vpn_eip.public_ip
}

