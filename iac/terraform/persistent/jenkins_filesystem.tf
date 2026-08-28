locals {
  bucket_arn = aws_s3_bucket.workspace_bucket.arn
  account_id = data.aws_caller_identity.current.account_id
}
data "aws_caller_identity" "current" {}
# data "aws_security_group" "server_sg" {
#   name = "jenkins-sg"
#   vpc_id = aws_vpc.todo_vpc.id
# }

resource "aws_s3_bucket" "workspace_bucket" {
  bucket           = format("jenkins-%s-%s-an", local.account_id, var.region)
  bucket_namespace = "account-regional"
  versioning {
    enabled = true
  }

  tags = {
    server = "jenkins"
  }

}

resource "aws_s3files_file_system" "s3_files" {
  bucket   = local.bucket_arn
  role_arn = aws_iam_role.s3_files_role.arn
  depends_on = [aws_s3_bucket.workspace_bucket]


}

resource "aws_s3files_mount_target" "s3_files_mount" {
  file_system_id = aws_s3files_file_system.s3_files.id
  subnet_id      = aws_subnet.web_sn_A.id
  security_groups = [aws_security_group.s3_files_sg.id]


}

resource "aws_s3files_access_point" "access_point" {
  file_system_id = aws_s3files_file_system.s3_files.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/jenkins"
    creation_permissions {
      owner_gid = 1000
      owner_uid = 1000
      permissions = 0755
    }

  }
}

output "filesystem_id" {
  value = aws_s3files_mount_target.s3_files_mount.file_system_id
}

resource "aws_security_group" "s3_files_sg" {
  name = "filesystem-sg"
  vpc_id = aws_vpc.todo_vpc.id

  tags = {
    Name = "filesystem-sg"
  }
}

resource "aws_security_group" "s3files_instance_sg" {
  name = "filesystem-instance-sg"
  vpc_id = aws_vpc.todo_vpc.id

  tags = {
    Name = "filesystem-instance-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "s3_files_rule" {
  ip_protocol       = "TCP"
  security_group_id = aws_security_group.s3_files_sg.id
  referenced_security_group_id = aws_security_group.s3files_instance_sg.id
  from_port = 2049
  to_port = 2049
}

resource "aws_vpc_security_group_egress_rule" "server_rule" {
  ip_protocol       = "TCP"
  security_group_id = aws_security_group.s3files_instance_sg.id
  referenced_security_group_id = aws_security_group.s3_files_sg.id
  from_port = 2049
  to_port = 2049
}


resource "aws_iam_role" "s3_files_role" {
  name = "s3_files_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowS3FilesAssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "elasticfilesystem.amazonaws.com"
        }

        Action = "sts:AssumeRole"

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }

          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3files:${var.region}:${local.account_id}:file-system/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_files_policy" {
  role   = aws_iam_role.s3_files_role.id
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "S3BucketPermissions"
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ]

        Resource = local.bucket_arn

        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      },

      {
        Sid    = "S3ObjectPermissions"
        Effect = "Allow"

        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject*",
          "s3:GetObject*",
          "s3:List*",
          "s3:PutObject*"
        ]

        Resource = "${local.bucket_arn}/*"

        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      },

      {
        Sid    = "UseKmsKeyWithS3Files"
        Effect = "Allow"

        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo"
        ]

        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.region.amazonaws.com"

            "kms:EncryptionContext:aws:s3:arn" = [
              local.bucket_arn,
              "${local.bucket_arn}/*"
            ]
          }
        }

        Resource = "arn:aws:kms:region:${local.account_id}:*"
      },

      {
        Sid    = "EventBridgeManage"
        Effect = "Allow"

        Action = [
          "events:DeleteRule",
          "events:DisableRule",
          "events:EnableRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets"
        ]

        Condition = {
          StringEquals = {
            "events:ManagedBy" = "elasticfilesystem.amazonaws.com"
          }
        }

        Resource = [
          "arn:aws:events:*:*:rule/DO-NOT-DELETE-S3-Files*"
        ]
      },

      {
        Sid    = "EventBridgeRead"
        Effect = "Allow"

        Action = [
          "events:DescribeRule",
          "events:ListRuleNamesByTarget",
          "events:ListRules",
          "events:ListTargetsByRule"
        ]

        Resource = [
          "arn:aws:events:*:*:rule/*"
        ]
      }
    ]
  })
}
