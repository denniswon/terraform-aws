locals {
  tf_asg_name = "${var.asg_name}-autoscaling-group"
  tf_volume_device = "/dev/xvdc"
  tf_userdata_map = {
    "userdata-ec2" = {
      tf_asg_name = local.tf_asg_name
      tf_workspace_snapshot_s3 = var.workspace_snapshot_s3_name
      tf_efs_id = var.efs_id
      tf_efs_accesspoint = var.efs_accesspoint
    }
    "userdata-ecs" = {
      tf_asg_name = var.asg_name
      tf_ecs_cluster = length(var.ecs_cluster) > 0 ? var.ecs_cluster : var.asg_name
    }
  }
  userdata = join("\n", [
    templatefile("${path.module}/${var.bootstrap_src}.sh", local.tf_userdata_map[var.bootstrap_src]),
    var.additional_user_data
  ])
}

resource aws_autoscaling_group asg {
  name                = local.tf_asg_name
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.instance_capacity
  max_size            = var.instance_capacity
  min_size            = var.instance_capacity

  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  target_group_arns         = var.target_group_arns
  load_balancers            = var.load_balancers
  default_cooldown          = var.default_cooldown
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes

  protect_from_scale_in = var.protect_from_scale_in

  launch_template {
    id      = aws_launch_template.tpl.id
    version = "$Latest"
  }
}

resource aws_launch_template tpl {
  name                    = local.tf_asg_name
  image_id                = var.ami_id
  instance_type           = var.instance_type
  user_data               = base64encode(local.userdata)
  key_name                = var.key_pair
  vpc_security_group_ids  = var.associate_public_ip ? null : var.security_group_ids
  ebs_optimized           = true
  disable_api_termination = var.disable_api_termination
  update_default_version  = var.update_default_version

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.iam_role.name
  }

  dynamic network_interfaces {
    for_each = var.associate_public_ip ? ["true"] : []
    content {
      associate_public_ip_address = true
      security_groups = var.security_group_ids
    }
  }

  block_device_mappings {
    device_name = var.root_device_name
    ebs {
      volume_type =  "gp2"
      volume_size = var.root_volume_size
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge({ Name = local.tf_asg_name, role = local.tf_asg_name }, var.additional_tags)
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge({ Name = local.tf_asg_name, role = local.tf_asg_name }, var.additional_tags)
  }

  tags = merge({ Name = local.tf_asg_name, role = local.tf_asg_name }, var.additional_tags)
}
