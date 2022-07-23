# public
resource aws_acm_certificate cloudfront {
  provider          = aws.global
  domain_name       = var.system_config["main_dns_domain"]
  subject_alternative_names = ["*.${var.system_config["main_dns_domain"]}"]
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource aws_acm_certificate alb {
  domain_name       = var.system_config["main_dns_domain"]
  subject_alternative_names = ["*.${var.system_config["main_dns_domain"]}"]
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource aws_acm_certificate_validation cloudfront {
  provider                = aws.global
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation_cloudfront : record.fqdn]
}

resource aws_acm_certificate_validation alb {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation_alb : record.fqdn]
}

resource aws_route53_record acm_validation_cloudfront {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

resource aws_route53_record acm_validation_alb {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# private
locals {
  ssl_allowed_uses = [
    "digital_signature",
    "content_commitment",
    "key_encipherment",
    "data_encipherment",
    "key_agreement",
    "cert_signing",
    "crl_signing",
    "encipher_only",
    "decipher_only",
    "any_extended",
    "server_auth",
    "client_auth",
    "code_signing",
    "email_protection",
    "ipsec_end_system",
    "ipsec_tunnel",
    "ipsec_user",
    "timestamping",
    "ocsp_signing",
    "microsoft_server_gated_crypto",
    "netscape_server_gated_crypto",
  ]
  ssl_validity_period_hours = 105120
  ssl_organization = "org"
}
resource tls_private_key private {
  algorithm   = "RSA"
  ecdsa_curve = "P224"
  lifecycle {
    ignore_changes = [ecdsa_curve]
  }
}

resource tls_self_signed_cert private_alb {
  private_key_pem = tls_private_key.private.private_key_pem
  subject {
    common_name  = "*.${local.zone_private_dns}"
    organization = local.ssl_organization
  }
  dns_names  = ["*.${local.zone_private_dns}"]
  allowed_uses = local.ssl_allowed_uses
  validity_period_hours = local.ssl_validity_period_hours
}

resource aws_iam_server_certificate private_alb {
  name_prefix      = "private-alb"
  certificate_body = tls_self_signed_cert.private_alb.cert_pem
  private_key      = tls_private_key.private.private_key_pem
  lifecycle {
    create_before_destroy = true
  }
}