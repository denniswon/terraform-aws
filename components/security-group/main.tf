variable vpc_id {}
variable group_name {}
variable default_ingress_cidrs { default = [] }
variable default_egress_cidrs { default = ["0.0.0.0/0"] }

resource aws_security_group sg {
    vpc_id = var.vpc_id
    name = var.group_name
    tags = {
        Name = var.group_name
    }
}

resource aws_security_group_rule ingress_self {
    type = "ingress"
    from_port = 0
    to_port = 65535
    protocol = "-1"
    self = true
    security_group_id  = aws_security_group.sg.id
}

resource aws_security_group_rule egress_self {
    type = "egress"
    from_port = 0
    to_port = 65535
    protocol = "-1"
    self = true
    security_group_id  = aws_security_group.sg.id
}

resource aws_security_group_rule default_ingress {
    count = length(var.default_ingress_cidrs) > 0 ? 1 : 0
    type = "ingress"
    from_port = 0
    to_port = 65535
    protocol = "-1"
    cidr_blocks = var.default_ingress_cidrs
    security_group_id  = aws_security_group.sg.id
}

resource aws_security_group_rule default_egress {
    type = "egress"
    from_port = 0
    to_port = 65535
    protocol = "-1"
    cidr_blocks = var.default_egress_cidrs
    security_group_id  = aws_security_group.sg.id
}