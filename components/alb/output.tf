output dns {
    value = aws_lb.alb.dns_name
}

output zone_id {
    value = aws_lb.alb.zone_id
}

output arn {
    value = aws_lb.alb.arn
}

output tg_http_fwd_arns {
    value = aws_lb_target_group.port_http
}

output tg_https_fwd_arns {
    value = aws_lb_target_group.port_https
}

output tg_grpc_fwd_arns {
    value = aws_lb_target_group.port_grpc
}

output tg_nlb_fwd_arn {
    value = aws_lb_target_group.port_nlb.*.arn
}

output tg_nlbs_fwd_arn {
    value = aws_lb_target_group.port_nlbs.*.arn
}