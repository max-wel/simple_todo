data "aws_vpc" "vpc" {
  tags = {
    Name = "todo-vpc"
  }
}

data "aws_subnet" "subnet" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    server = "jenkins"
  }
}

data "aws_security_group" "filesys_sg" {
  name = "filesystem-instance-sg"
  vpc_id = data.aws_vpc.vpc.id
}

data "aws_s3_bucket" "filesys_bucket" {
bucket = var.filesys_bucket_name
}

resource "aws_security_group" "jenkins_sg" {
  name = "jenkins-sg"
  description = "Allow traffic to jenkins server from my ip"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "TCP"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [var.my_ip]
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

module "ec2_s3files_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role"
  name = "s3-files-role"
  create_instance_profile = true
  trust_policy_permissions = {
    ec2 = {
      effect = "Allow"

      principals = [
        {
          type        = "Service"
          identifiers = ["ec2.amazonaws.com"]
        }
      ]

      actions = [
        "sts:AssumeRole"
      ]
    }
  }
  policies = {
    fileSystemAccess = data.aws_iam_policy.s3files_access.arn
    readAccess = aws_iam_policy.read_write_access.arn
  }
}

resource "aws_instance" "jenkins_server" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  iam_instance_profile = module.ec2_s3files_role.instance_profile_name

  subnet_id = data.aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id, data.aws_security_group.filesys_sg.id]
  key_name = aws_key_pair.server_key.key_name

  tags = {
    Name = "jenkins-server"
  }
}



resource "aws_iam_policy" "read_write_access" {
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "S3ObjectReadAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "${data.aws_s3_bucket.filesys_bucket.arn}/*"
      },

      {
        Sid    = "S3BucketListAccess"
        Effect = "Allow"

        Action   = "s3:ListBucket"
        Resource = data.aws_s3_bucket.filesys_bucket.arn
      }
    ]
  })
}

data "aws_iam_policy" "s3files_access" {
  name = "AmazonS3FilesClientFullAccess"
}




output "jenkins_server_url" {
  value = aws_instance.jenkins_server.public_dns
}