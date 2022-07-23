module ssm_log_s3 {
    source = "../components/s3"
    bucket_name = "${var.system_config["main_dns_domain"]}-ssm-log"
    # target_log_bucket = module.workspace_snapshot_s3.name
}

module alb_log_s3 {
    source = "../components/s3"
    bucket_name = "${var.system_config["main_dns_domain"]}-alb-log"
    # target_log_bucket = module.workspace_snapshot_s3.name
}

resource "aws_s3_bucket_policy" "alb_log_s3" {
  bucket = module.alb_log_s3.name
  policy = data.aws_iam_policy_document.alb_log_s3.json
}

data "aws_iam_policy_document" "alb_log_s3" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elb.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${module.alb_log_s3.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = ["bucket-owner-full-control"]
    }
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.system_config["aws_bucket_alb_id"]}:root"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${module.alb_log_s3.arn}/*",
    ]
  }
}