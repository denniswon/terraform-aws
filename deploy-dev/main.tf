terraform {
  required_version = ">=0.14"

  required_providers {
    aws  = "~> 3.74.1"
  }

  backend "s3" {
    bucket = "tf-interopera-dev"
    key    = "terraform/tf.state"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = local.system_config["aws_default_region"]
}

locals {
  system_config        = yamldecode(file("system-config.yaml"))
  asg_config           = yamldecode(file("asg-config.yaml"))
  ecs_config           = yamldecode(file("ecs-config.yaml"))
  ebs_config           = yamldecode(file("ebs-config.yaml"))
}

module "platform" {
  source               = "../platform"
  system_config        = local.system_config
  asg_config           = local.asg_config
  ecs_config           = local.ecs_config
  ebs_config           = local.ebs_config
}
