locals {
      aws_zones_indexes                  = ["a", "b", "c"]
      ecs_private_dns                    = "ecs.private"

      dns_jenkins                        = "jenkins.${var.system_config["main_dns_domain"]}"
      dns_monitor                        = "monitor.${var.system_config["main_dns_domain"]}"
      dns_prometheus                     = "prometheus.${var.system_config["main_dns_domain"]}"

      zone_private_dns                   = "internal.private"
      dns_private_loki                   = "loki.${local.zone_private_dns}"
      dns_private_prometheus             = "prometheus.${local.zone_private_dns}"
}

data "aws_caller_identity" "current" {}

data "aws_ami" "ecs" {
  owners      = [data.aws_caller_identity.current.account_id]
  most_recent = true
  filter {
    name   = "name"
    values = [var.system_config["ecs_ami_version"]]
  }
}