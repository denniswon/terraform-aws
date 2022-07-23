output name { value       = aws_s3_bucket.bucket.id }
output arn { value       = aws_s3_bucket.bucket.arn }
output dns { value       = aws_s3_bucket.bucket.bucket_domain_name }
output regional_dns { value       = aws_s3_bucket.bucket.bucket_regional_domain_name }
output hosted_zone_id { value       = aws_s3_bucket.bucket.hosted_zone_id }