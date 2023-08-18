# vpc構築
resource "aws_vpc" "main" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "okamemo_vpc"
  }
}

# パブリックサブネット構築
resource "aws_subnet" "public_1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"

  cidr_block        = "172.16.1.0/24"

  tags = {
    Name = "okamemo-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"

  cidr_block        = "172.16.2.0/24"

  tags = {
    Name = "okamemo-public-1c"
  }
}

# プライベートサブネット構築
resource "aws_subnet" "private_1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"
  cidr_block        = "172.16.10.0/24"

  tags = {
    Name = "okamemo-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"
  cidr_block        = "172.16.20.0/24"

  tags = {
    Name = "okamemo-private-1c"
  }
}

# インターネットゲートウェイ構築
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "okamemo-igw"
  }
}

# ルートテーブル作成（パブリック）
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "okamemo-public"
  }
}

# ルート設定（パブリック）
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# サブネット関連付け（パブリック）
resource "aws_route_table_association" "public-1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}
