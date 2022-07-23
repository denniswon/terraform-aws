resource aws_lb_listener port_http {
  count = var.alb_type == "application" ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  dynamic default_action {
    for_each = var.if_internal ? [] : [0]
    content {
      type = "redirect"
      redirect {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic default_action {
    for_each = var.if_internal ? [0] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "text/plain"
        message_body = "invalid request"
        status_code  = 400
      }
    }
  }
}

resource aws_lb_target_group port_http {
  for_each                      = var.port_http_fwd
  name                          = "tg-http-${each.key}"
  port                          = each.value["port"]
  protocol                      = each.value["protocol"]
  vpc_id                        = var.vpc_id
  target_type                   = lookup(each.value, "type", "ip")
  deregistration_delay          = 60
  slow_start                    = 0
  load_balancing_algorithm_type = "round_robin"
  health_check {
    interval            = 30
    path                = lookup(each.value, "hc_path", "/")
    port                = each.value["port"]
    protocol            = each.value["protocol"]
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = lookup(each.value, "hc_matcher", "200-302")
  }
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
}

resource aws_lb_listener_rule port_http {
  for_each     = var.port_http_fwd
  listener_arn = aws_lb_listener.port_http[0].arn
  priority     = each.value.priority + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_http[each.key].arn
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