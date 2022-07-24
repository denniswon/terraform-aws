# Provider
provider "aws" {
  alias = "this"
}

locals {
  tf_userdata_map = {
    "userdata-ecs" = [for index in range(var.instance_count): {
      tf_ecs_cluster = length(var.ecs_cluster) > 0 ? var.ecs_cluster : "ec2-${var.instance_name}${index + 1}"
      tf_ec2_name = "ec2-${var.instance_name}${index + 1}"
    }]
  }
}

# Resources
resource "aws_instance" "ec2" {
  count                       = var.instance_count
  provider                    = aws.this
  ami                         = var.ami_id
  instance_type               = var.instance_type[count.index]
  user_data                   = join("\n", [
    templatefile("${path.module}/${var.bootstrap_src}.sh", local.tf_userdata_map[var.bootstrap_src][count.index]),
    var.additional_user_data
  ])
  monitoring                  = true
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_ids[count.index % (length(var.subnet_ids))]
  associate_public_ip_address = var.has_public_ip
  iam_instance_profile        = var.role == "" ? aws_iam_instance_profile.iam_role[0].name : var.role
  placement_group             = var.placement_group
  private_ip                  = var.private_ip == null ? null : var.private_ip[count.index]
  ebs_optimized               = var.ebs_optimized
  disable_api_termination     = var.disable_api_termination

  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    iops        = var.root_iops
    throughput  = var.root_throughput
    encrypted   = var.root_encrypted
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      iops                  = ebs_block_device.value.iops
      throughput            = ebs_block_device.value.throughput
      encrypted             = ebs_block_device.value.volume_encrypted
      snapshot_id           = ebs_block_device.value.snapshot_id
      kms_key_id            = ebs_block_device.value.kms_key_id
      delete_on_termination = ebs_block_device.value.delete_on_termination
    }
  }

  tags = merge(
    {
      Name      = "ec2-${var.instance_name}${count.index + 1}",
    },
    var.tag_additional
  )

  volume_tags = merge(
    {
      Name      = "vol-${var.instance_name}${count.index + 1}",
    },
    var.tag_additional
  )

  lifecycle {
    ignore_changes = [
      user_data,
      ami
    ]
  }
}