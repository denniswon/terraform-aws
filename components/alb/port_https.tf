resource aws_lb_listener port_https {
  count             = length(keys(var.port_https_fwd)) + length(keys(var.port_grpc_fwd)) > 0 ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.default_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "invalid request"
      status_code  = 400
    }
  }
}

resource aws_lb_listener_certificate additional_certs {
  count           = length(var.additional_certificate_arns)
  listener_arn    = aws_lb_listener.port_https[0].arn
  certificate_arn = var.additional_certificate_arns[count.index]
}

resource aws_lb_target_group port_https {
  for_each                      = var.port_https_fwd
  name                          = "tg-https-${each.key}"
  port                          = each.value["port"]
  protocol                      = each.value["protocol"]
  vpc_id                        = var.vpc_id
  target_type                   = lookup(each.value, "type", "ip")
  deregistration_delay          = 60
  slow_start                    = 0
  load_balancing_algorithm_type = "round_robin"
  health_check {
    interval            = lookup(each.value, "hc_interval", 30) 
    path                = lookup(each.value, "hc_path", "/")
    port                = each.value["port"]
    protocol            = each.value["protocol"]
    timeout             = lookup(each.value, "hc_timeout", 5)
    healthy_threshold   = lookup(each.value, "hc_healthy", 5)
    unhealthy_threshold = lookup(each.value, "hc_unhealthy", 2)
    matcher             = lookup(each.value, "hc_matcher", "200-302")
  }
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
}

resource aws_lb_listener_rule port_https {
  for_each     = var.port_https_fwd
  listener_arn = aws_lb_listener.port_https[0].arn
  priority     = each.value.priority + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_https[each.key].arn
  }

  condition {
    host_header {
      values = [each.value.host]
    }
  }

  dynamic condition {
    for_each = lookup(each.value, "path", null) == null ? [] : [0]
    content {
      path_pattern {
        values = [each.value.path]
      }
    }
  }
}

resource aws_lb_target_group port_grpc {
  for_each                      = var.port_grpc_fwd
  name                          = "tg-grpc-${each.key}"
  port                          = each.value["port"]
  protocol                      = "HTTP"
  vpc_id                        = var.vpc_id
  target_type                   = lookup(each.value, "type", "ip")
  protocol_version              = "GRPC"

  health_check {
    interval            = 30
    path                = "/"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "0-99"
  }

  stickiness {
    type = "lb_cookie"
    enabled = false
  }
}

resource aws_lb_listener_rule port_grpc {
  for_each     = var.port_grpc_fwd
  listener_arn = aws_lb_listener.port_https[0].arn
  priority     = each.value.priority + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_grpc[each.key].arn
  }

  condition {
    host_header {
      values = [each.value.host]
    }
  }

  dynamic condition {
    for_each = lookup(each.value, "path", null) == null ? [] : [0]
    content {
      path_pattern {
        values = [each.value.path]
      }
    }
  }
}