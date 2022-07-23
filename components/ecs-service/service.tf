resource aws_ecs_service this {
  name        = var.app_name
  cluster     = var.cluster_id
  launch_type = var.launch_type

  task_definition      = aws_ecs_task_definition.this.arn
  desired_count        = var.resource_config["replicas"]
  enable_execute_command = var.enable_execute_command

  dynamic load_balancer {
    for_each = var.aws_lb_tg_arns
    content {
      target_group_arn = load_balancer.value.arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic network_configuration {
    for_each = try(var.resource_config.network, "awsvpc") == "awsvpc" ? [0] : []
    content {
      subnets          = var.subnet_ids
      security_groups  = var.security_group_ids
      assign_public_ip = false
    }
  }

  dynamic service_registries {
    for_each = var.discovery_namespace.enable ? [0] : []
    content {
      registry_arn = aws_service_discovery_service.this[0].arn
      container_name = try(var.discovery_namespace.container_name, null)
      container_port = try(var.discovery_namespace.container_port, null)
    }
  }

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}
