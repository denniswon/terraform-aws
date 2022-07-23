resource aws_iam_role execution_role {
  name               = "ecs-execution-role"
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

resource aws_iam_policy policy_ecr {
  name   = "ecs-execution-ecr"
  policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
                "ecr:GetAuthorizationToken", 
                "ecr:BatchCheckLayerAvailability", 
                "ecr:GetDownloadUrlForLayer", 
                "ecr:BatchGetImage"
            ]
            "Resource" = "*"
          },
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
        ]
  })
}

data aws_iam_policy amazone_ssm_full_access {
  arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource aws_iam_role_policy_attachment policy_ecr {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.policy_ecr.arn
}

resource aws_iam_role_policy_attachment amazone_ssm_full_access {
  role       = aws_iam_role.execution_role.name
  policy_arn = data.aws_iam_policy.amazone_ssm_full_access.arn
}