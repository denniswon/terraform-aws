resource aws_lb_listener port_nlb {
  count = var.port_nlb_fwd > 0 ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = var.port_nlb_fwd
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_nlb[0].arn
  }
}

resource aws_lb_target_group port_nlb {
  count       = var.port_nlb_fwd > 0 ? 1 : 0
  name        = "tg-${var.alb_name}-nlb"
  port        = var.port_nlb_fwd
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = var.nlb_target_type
  health_check {
    protocol            = "TCP"
    interval            = 30
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}