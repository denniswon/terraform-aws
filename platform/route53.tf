# public zone
resource "aws_route53_zone" "main" {
  name = var.system_config["main_dns_domain"]
}

resource "aws_route53_record" "cname_admin_alb" {
  for_each = toset([
    local.dns_jenkins,
    local.dns_monitor, 
    local.dns_prometheus,
  ])
  zone_id = aws_route53_zone.main.id
  name    = each.value
  type    = "CNAME"
  ttl     = 60
  records = [module.admin_alb.dns]
}

# private zone
resource "aws_route53_zone" "private" {
  name = local.zone_private_dns
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_record" "cname_private_alb" {
  for_each = toset([
    local.dns_private_loki,
    local.dns_private_prometheus,
  ])
  zone_id = aws_route53_zone.private.id
  name    = each.value
  type    = "CNAME"
  ttl     = 60
  records = [module.private_alb.dns]
}