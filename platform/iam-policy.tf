resource aws_iam_role jenkins_ecs {
  name               = "ecs-task-role-jenkins"
  assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = "sts:AssumeRole"
        Principal = {
            Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      }]
  })
}
resource aws_iam_policy jenkin_permission {
  name   = "jenkin-permission"
  policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {// Jenkin SSM
              Effect = "Allow"
              Action = [
                "ssm:StartSession",
                "ssm:TerminateSession",
                "ssm:SendCommand",
                "ssm:GetConnectionStatus",
                "ssm:DescribeInstanceInformation",
                "ssm:DescribeSessions",
                "ssm:DescribeInstanceProperties",
                "ssm:CreateDocument",
                "ssm:UpdateDocument",
                "ssm:GetDocument"
              ]
              Resource = "*"
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
          { // Jenkin packer
            Effect = "Allow"
            Action = [
              "ec2:AttachVolume",
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:CopyImage",
              "ec2:CreateImage",
              "ec2:CreateKeypair",
              "ec2:CreateSecurityGroup",
              "ec2:CreateSnapshot",
              "ec2:CreateTags",
              "ec2:CreateVolume",
              "ec2:DeleteKeyPair",
              "ec2:DeleteSecurityGroup",
              "ec2:DeleteSnapshot",
              "ec2:DeleteVolume",
              "ec2:DeregisterImage",
              "ec2:DescribeImageAttribute",
              "ec2:DescribeImages",
              "ec2:DescribeInstances",
              "ec2:DescribeInstanceStatus",
              "ec2:DescribeRegions",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeSnapshots",
              "ec2:DescribeSubnets",
              "ec2:DescribeTags",
              "ec2:DescribeVolumes",
              "ec2:DetachVolume",
              "ec2:GetPasswordData",
              "ec2:ModifyImageAttribute",
              "ec2:ModifyInstanceAttribute",
              "ec2:ModifySnapshotAttribute",
              "ec2:RegisterImage",
              "ec2:RunInstances",
              "ec2:StartInstances",
              "ec2:StopInstances",
              "ec2:TerminateInstances",
              "ec2:DescribeNetworkInterfaces",
              "ec2:CreateNetworkInterface",
              "ec2:DeleteNetworkInterface",
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "cloudfront:CreateInvalidation",
              "cloudfront:GetDistribution",
              "cloudfront:GetStreamingDistribution",
              "cloudfront:GetDistributionConfig",
              "cloudfront:GetInvalidation",
              "cloudfront:ListInvalidations",
              "cloudfront:ListStreamingDistributions",
              "cloudfront:ListDistributions"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "ecs:*"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "iam:PassRole"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "ssm:GetParameter"
            ]
            Resource = [
              "arn:aws:ssm:*:*:parameter/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id",
              "arn:aws:ssm:*:*:parameter/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs",
              "arn:aws:ssm:*:*:parameter/aws/service/canonical/ubuntu/server/focal/stable/current/amd64/hvm/ebs-gp2/ami-id"
            ]
          },
          {
            Effect = "Allow"
            Action = [
              "elasticfilesystem:CreateFileSystem",
              "elasticfilesystem:CreateMountTarget",
              "elasticfilesystem:CreateTags",
              "elasticfilesystem:DescribeFileSystems",
              "elasticfilesystem:DescribeMountTargets",
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "s3:PutObject",
              "s3:PutObjectAcl",
              "s3:GetObject",
              "s3:ListBucket",
            ]
            Resource = [
              module.ssm_log_s3.arn,
              "${module.ssm_log_s3.arn}/*",
            ]
          },
          {
            Effect = "Allow"
            Action = [
              "s3:DeleteObject"
            ]
            Resource = ["${module.ssm_log_s3.arn}/*"]
          },
        ]
  })
}

resource aws_iam_role_policy_attachment jenkins_ecs {
  role       = aws_iam_role.jenkins_ecs.id
  policy_arn = aws_iam_policy.jenkin_permission.arn
}
resource aws_iam_role_policy_attachment jenkins_ecs_cmd {
  role       = aws_iam_role.jenkins_ecs.id
  policy_arn = aws_iam_policy.execute_ecs_cmd.arn
}
resource aws_iam_role_policy_attachment asg_admin_jenkins {
  count      = length(module.asg_admin_jenkins)
  role       = module.asg_admin_jenkins[count.index].ec2_iam_role_id
  policy_arn = aws_iam_policy.jenkin_permission.arn
}

# ssm_cert_grpc
resource aws_iam_policy ssm_cert_grpc {
  name   = "ssm-cert-grpc"
  policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "ssm:GetParameter"
            ]
            Resource = aws_ssm_parameter.private_ssl_cert.arn
          }
        ]
  })
}

# monitor
resource aws_iam_policy grafana {
  name     = "grafana-cw-access"
  policy   = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "cloudwatch:DescribeAlarmsForMetric",
            "cloudwatch:DescribeAlarmHistory",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:ListMetrics",
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:GetMetricData"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "logs:DescribeLogGroups",
            "logs:GetLogGroupFields",
            "logs:StartQuery",
            "logs:StopQuery",
            "logs:GetQueryResults",
            "logs:GetLogEvents"
          ]
          "Resource" = "*"
        },
        {
          Effect = "Allow"
          Action = ["ec2:DescribeTags", "ec2:DescribeInstances", "ec2:DescribeRegions"]
          "Resource" = "*"
        },
        {
          Effect = "Allow"
          Action = "tag:GetResources"
          "Resource" = "*"
        },
      ]
  })
}

resource aws_iam_role_policy_attachment grafana_cloudwatch {
  role       = aws_iam_role.jenkins_ecs.name
  policy_arn = aws_iam_policy.grafana.arn
}

resource null_resource vpc_trunking_monitor {
  provisioner "local-exec" {
    command = <<EOF
aws ecs put-account-setting-default --region ${var.system_config["aws_default_region"]} --name awsvpcTrunking --value enabled                       
EOF
  }
}

# execute ecs cmd
resource aws_iam_policy execute_ecs_cmd {
  name     = "execute-ecs-cmd"
  policy   = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ]
          "Resource" = "*"
        },
      ]
  })
}

resource aws_iam_role cloudfront_lambda {
  name               = "cf-lambda"
  assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = "sts:AssumeRole"
        Principal = {
            Service = ["edgelambda.amazonaws.com", "lambda.amazonaws.com"]
        }
        Effect = "Allow"
      }]
  })
}