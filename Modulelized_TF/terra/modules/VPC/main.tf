resource "aws_vpc" "main" { # VPC 생성
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "MyVPC"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "igw" { # 인터넷 게이트웨이 생성
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "MyVPC-IGW"
    Environment = var.environment
  }
}

resource "aws_subnet" "public1" { # 퍼블릭 서브넷 1 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet1_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public-Subnet-1"
    Environment = var.environment
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }
}

resource "aws_subnet" "public2" { # 퍼블릭 서브넷 2 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet2_cidr
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public-Subnet-2"
    Environment = var.environment
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }
}

resource "aws_subnet" "private1" { # 프라이빗 서브넷 1 생성
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet1_cidr
  availability_zone = "${var.region}a"

  tags = {
    Name        = "Private-Subnet-1"
    Environment = var.environment
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }
}

resource "aws_subnet" "private2" { # 프라이빗 서브넷 2 생성
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet2_cidr
  availability_zone = "${var.region}c"

  tags = {
    Name        = "Private-Subnet-2"
    Environment = var.environment
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }
}

resource "aws_eip" "nat_eip" { # NAT 게이트웨이용 EIP 생성
  domain = "vpc"
  tags = {
    Name        = "NAT-EIP"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "nat" { # NAT 게이트웨이 생성
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name        = "NAT-GW"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" { # 퍼블릭 라우트 테이블 생성
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "Public-RT"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" { # 프라이빗 라우트 테이블 생성
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "Private-RT"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public1" { # 퍼블릭 서브넷 1과 퍼블릭 라우트 테이블 연결
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" { # 퍼블릭 서브넷 2와 퍼블릭 라우트 테이블 연결
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" { # 프라이빗 서브넷 1과 프라이빗 라우트 테이블 연결
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" { # 프라이빗 서브넷 2와 프라이빗 라우트 테이블 연결
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
