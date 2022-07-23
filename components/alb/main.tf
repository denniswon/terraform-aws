resource aws_lb alb {
  name                       = var.alb_name
  internal                   = var.if_internal
  load_balancer_type         = var.alb_type
  security_groups            = var.security_group_ids
  subnets                    = var.subnet_ids
  ip_address_type            = "ipv4"
  enable_deletion_protection = true
  idle_timeout               = 60
  access_logs {
    bucket  = var.alb_log_bucket
    prefix  = var.alb_name
    enabled = true
  }
}

resource aws_wafv2_web_acl_association wafv2 {
  count        = var.webaclv2.enabled ? 1 : 0
  resource_arn = aws_lb.alb.arn
  web_acl_arn  = var.webaclv2.arn
}