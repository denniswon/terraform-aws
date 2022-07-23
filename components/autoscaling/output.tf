output asg_id {
  value       = aws_autoscaling_group.asg.id
}

output asg_arn {
  value       = aws_autoscaling_group.asg.arn
}

output asg_name {
  value       = aws_autoscaling_group.asg.name
}

output ecs_tagid {
  value       = var.asg_name
}

output launch_template_id {
  value       = aws_launch_template.tpl.id
}

output launch_template_arn {
  value       = aws_launch_template.tpl.arn
}

output ec2_iam_role_id {
  value       = aws_iam_role.iam_role.id 
}