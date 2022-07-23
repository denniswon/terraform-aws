output efs_id {
    value = aws_efs_file_system.efs.id
}

output dns {
    value = aws_efs_file_system.efs.dns_name
}

output access_point_ids {
    value = aws_efs_access_point.efs
}