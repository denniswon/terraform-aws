resource aws_s3_bucket_public_access_block cf {
  count = var.cf_origin_access_identity.enable ? 1 : 0
	bucket = aws_s3_bucket.bucket.id
	block_public_acls   = true
	block_public_policy = true
	ignore_public_acls   = true
	restrict_public_buckets = true
}

data aws_iam_policy_document cf {
  count = var.cf_origin_access_identity.enable ? 1 : 0
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [var.cf_origin_access_identity.arn]
    }
  }
}

resource aws_s3_bucket_policy cf {
  count = var.cf_origin_access_identity.enable ? 1 : 0
	bucket = aws_s3_bucket.bucket.id
	policy = data.aws_iam_policy_document.cf[0].json
}