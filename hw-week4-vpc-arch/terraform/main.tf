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

resource "aws_vpc" "this" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "week4-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "week4-igw" }
}

# Public subnets (one per AZ)
resource "aws_subnet" "public" {
  for_each = {
    a = { az = "sa-east-1a", cidr = "10.42.0.0/24" }
    b = { az = "sa-east-1b", cidr = "10.42.1.0/24" }
    c = { az = "sa-east-1c", cidr = "10.42.2.0/24" }
  }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "public-${each.key}"
    Tier = "public"
  }
}

# EIPs and NAT Gateways (one per AZ)
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain = "vpc"
  tags = { Name = "nat-eip-${each.key}" }
}

resource "aws_nat_gateway" "this" {
  for_each = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = { Name = "nat-${each.key}" }

  depends_on = [aws_internet_gateway.this]
}

# Private app subnets (one per AZ)
resource "aws_subnet" "private_app" {
  for_each = {
    a = { az = "sa-east-1a", cidr = "10.42.10.0/24" }
    b = { az = "sa-east-1b", cidr = "10.42.11.0/24" }
    c = { az = "sa-east-1c", cidr = "10.42.12.0/24" }
  }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "private-app-${each.key}"
    Tier = "private-app"
  }
}

# Private db subnets (one per AZ)
resource "aws_subnet" "private_db" {
  for_each = {
    a = { az = "sa-east-1a", cidr = "10.42.20.0/24" }
    b = { az = "sa-east-1b", cidr = "10.42.21.0/24" }
    c = { az = "sa-east-1c", cidr = "10.42.22.0/24" }
  }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "private-db-${each.key}"
    Tier = "private-db"
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "public-rt" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# Private route tables (one per AZ → that AZ's NAT)
resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.this
  vpc_id = aws_vpc.this.id
  tags = { Name = "private-rt-${each.key}" }
}

resource "aws_route" "private_default" {
  for_each = aws_route_table.private
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private_app_assoc" {
  for_each = aws_subnet.private_app
  subnet_id      = aws_subnet.private_app[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "private_db_assoc" {
  for_each = aws_subnet.private_db
  subnet_id      = aws_subnet.private_db[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
