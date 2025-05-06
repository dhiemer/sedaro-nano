###################################################################
# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

###################################################################
# Public Subnets
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = var.aws_azs_primary["primary"]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

#resource "aws_subnet" "public2" {
#  provider                = aws.usw2
#  vpc_id                  = aws_vpc.main.id
#  cidr_block              = "10.10.2.0/24"
#  availability_zone       = var.aws_azs_secondary["secondary"]
#
#  map_public_ip_on_launch = true
#
#  tags = {
#    Name = "public-subnet-2"
#  }
#}


###################################################################
# Private Subnets
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = var.aws_azs_primary[var.az_preference]

  tags = {
    Name = "private-subnet-1"
  }
}

#resource "aws_subnet" "private2" {
#  provider          = aws.usw2
#  vpc_id            = aws_vpc.main.id
#  cidr_block        = "10.10.4.0/24"
#  availability_zone = var.aws_azs_secondary[var.az_preference]
#
#  tags = {
#    Name = "private-subnet-2"
#  }
#}


###################################################################
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "sedaro-igw"
  }
}

###################################################################
# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  } 
  
  tags = {
    Name = "private-route-table"
  }
}

###################################################################
# Route Table Associations
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}



###################################################################
# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id
  
  tags = {
    Name = "sedaro-nat-gateway"
  }
  
  depends_on = [aws_internet_gateway.igw]
}

# Elastic Public IP
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "sedaro-nat-eip"
  }
}
