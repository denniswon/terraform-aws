data aws_canonical_user_id current {}

resource aws_s3_bucket bucket {
  bucket        = "tf-s3-${var.bucket_name}"
  force_destroy = true

  acl = var.acl_config

  versioning {
    enabled = var.bucket_versioning
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  dynamic grant {
    for_each    = var.acl_config == null ? [var.acl_config] : []
    content {
      id          = data.aws_canonical_user_id.current.id
      type        = "CanonicalUser"
      permissions = ["FULL_CONTROL"]
    }
  }

  dynamic "cors_rule" {
    for_each = try(jsondecode(var.cors_rule), var.cors_rule)
    content {
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }

  #s3 object lock
  dynamic "object_lock_configuration" {
    for_each = length(var.object_lock_configuration) != 0 ? [var.object_lock_configuration] : []

    content {
      object_lock_enabled = "Enabled"

      dynamic "rule" {
        for_each = length(var.object_lock_configuration.rule) != 0 ? [var.object_lock_configuration.rule] : []

        content {
          default_retention {
            mode  = lookup(rule.value.default_retention, "mode", null)
            days  = lookup(rule.value.default_retention, "days", null)
            years = lookup(rule.value.default_retention, "years", null)
          }
        }
      }
    }
  }

  dynamic logging {
    for_each = length(var.target_log_bucket) > 0 ? ["default"] : []
    content {
      target_bucket = var.target_log_bucket
      target_prefix = "tf-s3-${var.bucket_name}/"
    }
  }

  tags = {
    Name        = "tf-s3-${var.bucket_name}"
    "tf-s3-${var.bucket_name}"        = "tf-s3-${var.bucket_name}"
  }

  lifecycle {
    ignore_changes = [grant]
  }
}

resource aws_s3_bucket_metric metric {
  count = var.acl_config == null ? 1 : 0
  bucket = aws_s3_bucket.bucket.bucket
  name   = "tf-s3-${var.bucket_name}-metrics"
}