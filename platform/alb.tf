module "admin_alb" {
  source                  = "../components/alb"
  alb_name                = "admin-alb"
  vpc_id                  = module.vpc.vpc_id
  if_internal             = false
  subnet_ids              = module.vpc.subnet_public_ids
  security_group_ids      = [module.admin_alb_security_group.security_group_id]
  alb_log_bucket          = module.alb_log_s3.name
  default_certificate_arn = aws_acm_certificate.alb.arn
  port_https_fwd = {
    "jenkins" = { priority = 0, hc_matcher = "200,403", protocol = "HTTP", port = 8080, host = local.dns_jenkins }
    "grafana" = { priority = 1, protocol = "HTTP", port = 3000, host = local.dns_monitor }
    "prometheus" = { priority = 3, protocol = "HTTP", port = 9090, host = local.dns_prometheus }
  }
}

module "private_alb" {
  source                  = "../components/alb"
  alb_name                = "private-alb"
  if_internal             = true
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.subnet_private_with_nat_ids
  security_group_ids      = [module.private_alb_security_group.security_group_id]
  alb_log_bucket          = module.alb_log_s3.name
  default_certificate_arn = aws_iam_server_certificate.private_alb.arn
  port_http_fwd = {
    "loki" = { priority = 0, hc_matcher = "200,404", protocol = "HTTP", port = 3100, host = local.dns_private_loki }
    "prometheus" = { priority = 7, protocol = "HTTP", port = 9090, host = local.dns_private_prometheus }
  }
}