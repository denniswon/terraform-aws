output "ec2_id" { value       = aws_instance.ec2.id }
output "ec2_availability_zone" { value       = aws_instance.ec2.availability_zone }
output "ec2_iam_role_id" { value       = aws_iam_role.iam_role.id }
output "ec2_private_ip" { value       = aws_instance.ec2.private_ip }
output "ec2_vol_tags" { value = aws_instance.ec2.volume_tags }