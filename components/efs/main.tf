resource aws_efs_file_system efs {
  creation_token = var.fs_unique_name
  tags = {
    Name = var.fs_unique_name
  }
  encrypted = true
  lifecycle {
    prevent_destroy = true
  }
}

resource aws_efs_mount_target efs {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.vpc_security_group_ids
}
resource aws_efs_access_point efs {
  for_each = var.access_points
  file_system_id = aws_efs_file_system.efs.id
  root_directory {
    creation_info {
      owner_gid = each.value.owner_gid
      owner_uid = each.value.owner_gid
      permissions = 777
    }
    path = "${each.value.root_path}/${each.key}"
  }
  posix_user {
    gid = each.value.owner_gid
    uid = each.value.owner_gid
  }
}