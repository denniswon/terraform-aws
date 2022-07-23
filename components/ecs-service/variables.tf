variable app_name {}
variable cluster_id {}
variable dns_private_loki {}
variable security_group_ids {}
variable subnet_ids {}
variable execution_role_arn {}
variable containers {}
variable fluentbit_plugin_image {}
variable logConfiguration { default = null }
variable discovery_namespace { 
  default = {
    enable = false
    id = null
  }
}
variable task_role_arn { default = null }
variable placementConstraints { default = [] }
variable aws_lb_tg_arns { default = [] }
variable volumes { default = [] }
variable launch_type { default = "EC2" }
variable resource_config {
  default = {
    cpu = null
    memory = null
    image = null
    replicas = 0
  }
}
variable enable_execute_command { default = null }
variable memoryReservation { default = null }