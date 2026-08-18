terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "my_ip" {}

# create vpc
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

resource "aws_security_group" "jenkins_sg" {
  name = "allow_http"
  description = "Allow traffic to jenkins server from my ip"
  vpc_id = aws_vpc.todo_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = [var.my_ip] #change to your ip
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [var.my_ip] #change to your ip
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["al2023-ami-2023*"]
  }

}

resource "aws_key_pair" "server_key" {
  key_name = "server-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "jenkins_server" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.web_sn_A.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name = aws_key_pair.server_key.key_name

  tags = {
    Name = "jenkins-server"
  }
}

output "jenkins_server_url" {
  value = aws_instance.jenkins_server.public_dns
}