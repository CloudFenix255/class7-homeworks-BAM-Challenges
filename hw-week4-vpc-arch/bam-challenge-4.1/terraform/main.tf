terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "bam" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "bam-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.bam.id
  tags   = { Name = "bam-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.bam.id
  cidr_block              = "10.50.0.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "bam-public-a" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.bam.id
  cidr_block        = "10.50.10.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "bam-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.bam.id
  cidr_block        = "10.50.11.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "bam-private-b" }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.bam.id
  cidr_block        = "10.50.12.0/24"
  availability_zone = "${var.aws_region}c"
  tags = { Name = "bam-private-c" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.bam.id
  tags   = { Name = "bam-public-rt" }
}

resource "aws_route" "igw_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_a.id
}

resource "aws_security_group" "bastion_sg" {
  name        = "bam-bastion-sg"
  description = "RDP from allowed CIDR, SSH/HTTP egress to private"
  vpc_id      = aws_vpc.bam.id

  ingress {
    description = "RDP from allowed CIDR"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bam-bastion-sg" }
}

resource "aws_security_group" "web_sg" {
  name        = "bam-web-sg"
  description = "Allow SSH/HTTP from bastion SG"
  vpc_id      = aws_vpc.bam.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description     = "HTTP from bastion"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bam-web-sg" }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.windows.id
  instance_type               = "t3.large"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  tags = { Name = "bam-windows-bastion" }
}

locals {
  web_userdata = {
    a = <<-EOT
      #!/bin/bash
      set -eux
      mkdir -p /var/www/html
      cat >/var/www/html/index.html <<'HTML'
      <!doctype html><html><head><meta charset="utf-8"><title>BAM - AZ A</title></head>
      <body style="font-family:Arial, sans-serif">
      <h1>BAM Challenge – Web A (AZ-a)</h1>
      <p>This is the AZ <strong>a</strong> server in 10.50.10.0/24.</p>
      <img alt="Triangle" src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='320' height='220'><polygon points='160,20 300,200 20,200' style='fill:orange;stroke:black;stroke-width:3'/></svg>"/>
      </body></html>
      HTML
      nohup python3 -m http.server 80 --directory /var/www/html >/var/log/web_a.http.log 2>&1 &
    EOT
    b = <<-EOT
      #!/bin/bash
      set -eux
      mkdir -p /var/www/html
      cat >/var/www/html/index.html <<'HTML'
      <!doctype html><html><head><meta charset="utf-8"><title>BAM - AZ B</title></head>
      <body style="font-family:Arial, sans-serif">
      <h1>BAM Challenge – Web B (AZ-b)</h1>
      <p>This is the AZ <strong>b</strong> server in 10.50.11.0/24.</p>
      <img alt="Circle" src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='220' height='220'><circle cx='110' cy='110' r='90' stroke='black' stroke-width='3' fill='lightblue' /></svg>"/>
      </body></html>
      HTML
      nohup python3 -m http.server 80 --directory /var/www/html >/var/log/web_b.http.log 2>&1 &
    EOT
    c = <<-EOT
      #!/bin/bash
      set -eux
      mkdir -p /var/www/html
      cat >/var/www/html/index.html <<'HTML'
      <!doctype html><html><head><meta charset="utf-8"><title>BAM - AZ C</title></head>
      <body style="font-family:Arial, sans-serif">
      <h1>BAM Challenge – Web C (AZ-c)</h1>
      <p>This is the AZ <strong>c</strong> server in 10.50.12.0/24.</p>
      <img alt="Squares" src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='320' height='220'><rect x='20' y='20' width='80' height='80' fill='pink' stroke='black' stroke-width='3'/><rect x='120' y='70' width='80' height='80' fill='lightgreen' stroke='black' stroke-width='3'/><rect x='220' y='120' width='80' height='80' fill='yellow' stroke='black' stroke-width='3'/></svg>"/>
      </body></html>
      HTML
      nohup python3 -m http.server 80 --directory /var/www/html >/var/log/web_c.http.log 2>&1 &
    EOT
  }
}

resource "aws_instance" "web_a" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.ssh_key_name
  user_data              = local.web_userdata.a
  associate_public_ip_address = false
  tags = { Name = "bam-web-a" }
}

resource "aws_instance" "web_b" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_b.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.ssh_key_name
  user_data              = local.web_userdata.b
  associate_public_ip_address = false
  tags = { Name = "bam-web-b" }
}

resource "aws_instance" "web_c" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_c.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.ssh_key_name
  user_data              = local.web_userdata.c
  associate_public_ip_address = false
  tags = { Name = "bam-web-c" }
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "web_private_ips" {
  value = {
    a = aws_instance.web_a.private_ip
    b = aws_instance.web_b.private_ip
    c = aws_instance.web_c.private_ip
  }
}
