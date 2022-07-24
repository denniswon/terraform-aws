module ecs_iam {
  source = "../components/aws-iam/ecs"
}

resource aws_service_discovery_private_dns_namespace ecs {
  name = var.system_config["ecs_private_dns"]
  vpc  = module.vpc.vpc_id
}

# admin ec2 cluster
resource aws_ecs_cluster admin {
  name = "admin"
}
module "asg_admin_jenkins" {
  source                     = "../components/autoscaling"
  count                      = var.ec2_config["ecs-jenkins"]["capacity"]
  ami_id                     = data.aws_ami.ecs.id
  asg_name                   = "${aws_ecs_cluster.admin.name}-jenkins-${count.index}"
  ecs_cluster                = aws_ecs_cluster.admin.name
  instance_type              = var.ec2_config["ecs-jenkins"]["instance_type"]
  root_volume_size           = var.ec2_config["ecs-jenkins"]["root_volume_size"]
  security_group_ids         = [module.ecs_security_group.security_group_id]
  subnet_ids                 = [module.vpc.subnet_private_with_nat_ids[count.index % 3]]
  ssm_log_s3_arn             = module.ssm_log_s3.arn
  ssm_decrypt_key_arn        = aws_kms_key.ssm_s3.arn
  bootstrap_src              = "userdata-ecs"
  additional_tags = {
    group     = "ecs-${aws_ecs_cluster.admin.name}-jenkins"
    component = "ecs"
  }
}

module "asg_admin_monitors" {
  source                     = "../components/autoscaling"
  count                      = var.ec2_config["ecs-monitors"]["capacity"]
  ami_id                     = data.aws_ami.ecs.id
  asg_name                   = "${aws_ecs_cluster.admin.name}-monitors-${count.index}"
  ecs_cluster                = aws_ecs_cluster.admin.name
  instance_type              = var.ec2_config["ecs-monitors"]["instance_type"]
  root_volume_size           = var.ec2_config["ecs-monitors"]["root_volume_size"]
  security_group_ids         = [module.ecs_security_group.security_group_id]
  subnet_ids                 = [module.vpc.subnet_private_with_nat_ids[count.index % 3]]
  ssm_log_s3_arn             = module.ssm_log_s3.arn
  ssm_decrypt_key_arn        = aws_kms_key.ssm_s3.arn
  bootstrap_src              = "userdata-ecs"
  additional_tags = {
    group     = "ecs-${aws_ecs_cluster.admin.name}-monitors"
    component = "ecs"
  }
}

# gaia blockchain cluster
resource "aws_eip" "validators" {
  count    = length(var.system_config["chain_gaia"]["VALIDATOR_STATIC_IPS"])
  vpc      = true
}
