resource aws_ecs_task_definition this {
  family                   = var.app_name
  requires_compatibilities = [var.launch_type]
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn
  network_mode             = try(var.resource_config.network, "awsvpc")
  cpu                      = try(var.resource_config.cpu, null)
  memory                   = try(var.resource_config.memory, null)
  
  dynamic placement_constraints {
    for_each = var.placementConstraints
    content {
      expression = placement_constraints.value.expression
      type = placement_constraints.value.type
    }
  }

  dynamic volume {
    for_each = var.volumes
    content {
      name      = volume.value.name
      host_path = try(volume.value.host_path, null)
      dynamic docker_volume_configuration {
        for_each = can(volume.value.docker_volume_configuration) ? [try(volume.value.docker_volume_configuration, {})] : []
        content {
          scope         = try(docker_volume_configuration.value.scope, null)
          autoprovision = try(docker_volume_configuration.value.autoprovision, null)
          driver        = try(docker_volume_configuration.value.driver, null)
        }
      }

      dynamic efs_volume_configuration {
        for_each = can(volume.value.efs_volume_configuration) ? [try(volume.value.efs_volume_configuration, {})] : []
        content {
          file_system_id         = try(efs_volume_configuration.value.file_system_id, null)
          transit_encryption = "ENABLED"
          authorization_config {
            access_point_id = efs_volume_configuration.value.access_point_id
            iam             = "ENABLED"
          }
        }
      }
    }
  }

  container_definitions = jsonencode(
    concat(
      var.logConfiguration == null ? [
        {
          cpu = 0
          user = "0" 
          essential = true
          name = "fluentbit"
          image = var.fluentbit_plugin_image
          memoryReservation = var.memoryReservation
          portMappings = []
          environment = []
          mountPoints = []
          placementConstraints = []
          volumes = []
          volumesFrom = []
          firelensConfiguration = {
            type = "fluentbit"
            options = {
              "enable-ecs-log-metadata" = "true"
            }
          }
        }
      ] : [],
      [for container in var.containers: merge(
        { 
          cpu = 0,
          memoryReservation = var.memoryReservation,
          essential        = true,
          mountPoints = [], 
          volumesFrom = [],
          portMappings = [],
          logConfiguration = var.logConfiguration != null ? var.logConfiguration : {
            logDriver = "awsfirelens"
            options = {
              Name = "grafana-loki"
              Url = "http://${var.dns_private_loki}/loki/api/v1/push"
              Labels = "{container_tag=\"ecs.${length(var.containers) == 1 ? var.app_name : container.name}\"}"
              RemoveKeys = "container_name,ecs_task_arn,ecs_task_definition,ecs_cluster"
              LabelKeys = "container_id,source"
              LineFormat = "key_value"
            }
          }
        }, 
        container
      )]
    )
  )
}
