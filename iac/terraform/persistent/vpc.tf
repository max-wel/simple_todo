resource "aws_vpc" "todo_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name: "todo-vpc"
  }
}

resource "aws_subnet" "web_sn_A" {
  vpc_id = aws_vpc.todo_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "web-sn-A"
    server = "jenkins"
  }
}

resource "aws_internet_gateway" "todo_igw" {
  vpc_id = aws_vpc.todo_vpc.id

  tags = {
    Name = "todo-igw"
  }
}

resource "aws_route_table" "todo_rt" {
  vpc_id = aws_vpc.todo_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.todo_igw.id
  }

  tags = {
    Name = "todo-rt"
  }
}

resource "aws_route_table_association" "todo_rt_assoc" {
  route_table_id = aws_route_table.todo_rt.id
  subnet_id = aws_subnet.web_sn_A.id
}