resource "aws_iam_role" "iam_role" {
  name        = var.instance_name
  assume_role_policy = jsonencode({
      Version = "2008-10-17"
      Statement = [
          {
              Effect = "Allow"
              Principal = {
                  Service = "ec2.amazonaws.com"
              }
              Action = "sts:AssumeRole"
          }
      ]
  })
}

resource "aws_iam_instance_profile" "iam_role" {
  name_prefix = var.instance_name
  role        = aws_iam_role.iam_role.name
}

resource aws_iam_role_policy ec2_ssm {
  name     = "EC2SessionManager"
  role     = aws_iam_role.iam_role.id
  policy   = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
            "ssm:UpdateInstanceInformation",
            "ssm:DescribeAssociation",
            "ssm:GetDeployablePatchSnapshotForInstance",
            "ssm:GetDocument",
            "ssm:DescribeDocument",
            "ssm:GetManifest",
            "ssm:GetParameters",
            "ssm:ListAssociations",
            "ssm:ListInstanceAssociations",
            "ssm:UpdateAssociationStatus",
            "ssm:UpdateInstanceAssociationStatus"
          ]
          Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
              "ec2messages:AcknowledgeMessage",
              "ec2messages:DeleteMessage",
              "ec2messages:FailMessage",
              "ec2messages:GetEndpoint",
              "ec2messages:GetMessages",
              "ec2messages:SendReply"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = "cloudwatch:PutMetricData"
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
              "ec2:Describe*",
              "ec2:CreateTags",
              "ec2:AttachVolume",
              "ec2:DetachVolume"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
              "s3:PutObject",
              "s3:PutObjectAcl",
              "s3:GetObject",
              "s3:ListBucket"
            ]
            Resource = [
              var.ssm_log_s3_arn,
              "${var.ssm_log_s3_arn}/*",
              "arn:aws:s3:::${var.workspace_snapshot_s3_name}",
              "arn:aws:s3:::${var.workspace_snapshot_s3_name}/*"
            ]
        },
        {
            Effect = "Allow"
            Action = [
              "s3:GetEncryptionConfiguration"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = "kms:GenerateDataKey"
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = "kms:Decrypt"
            Resource = var.ssm_decrypt_key_arn
        },
        {
          Effect = "Allow"
          Action = [
            "s3:DeleteObject"
          ]
          Resource = ["${var.ssm_log_s3_arn}/*", "arn:aws:s3:::${var.workspace_snapshot_s3_name}/*"]
        },
        {
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:InitiateLayerUpload",
            "ecr:ListImages",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeImages",
            "ecr:BatchCheckLayerAvailability",
            "ecr:DescribeRepositories",
            "ecr:BatchDeleteImage"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ecs:CreateCluster",
            "ecs:DeregisterContainerInstance",
            "ecs:DiscoverPollEndpoint",
            "ecs:Poll",
            "ecs:RegisterContainerInstance",
            "ecs:StartTelemetrySession",
            "ecs:UpdateContainerInstancesState",
            "ecs:Submit*",
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:CopySnapshot",
            "ec2:DeleteSnapshot",
            "ec2:ModifyVolumeAttribute",
            "ec2:DescribeTags",
            "ec2:DescribeSnapshotAttribute",
            "ec2:DescribeSnapshots",
            "ec2:CreateVolume",
            "ec2:DeleteVolume",
            "ec2:DescribeVolumeStatus",
            "ec2:ModifySnapshotAttribute",
            "ec2:DescribeVolumes",
            "ec2:CreateSnapshot",
            "ec2:DescribeInstances"
          ]
          Resource = "*"
        }
      ]
  })
}