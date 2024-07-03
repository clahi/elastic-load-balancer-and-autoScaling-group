resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability-zone-1a
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1a"
  }
}

resource "aws_subnet" "public_subnet_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.availability-zone-1b
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1b"
  }
}

resource "aws_internet_gateway" "main_ig" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_ig"
  }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_rt"
  }
}

resource "aws_route" "public_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_ig.id
  route_table_id         = aws_route_table.main_rt.id
}

resource "aws_route_table_association" "rt_association_1a" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.main_rt.id

}

resource "aws_route_table_association" "rt_association_1b" {
  subnet_id      = aws_subnet.public_subnet_1b.id
  route_table_id = aws_route_table.main_rt.id

}