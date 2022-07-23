# jenkin
module  jenkin_master {
  source = "../components/ecs-service"
  cluster_id              = aws_ecs_cluster.admin.id
  app_name                = "jenkins-master"
  subnet_ids              = module.vpc.subnet_private_with_nat_ids
  security_group_ids      = [module.ecs_security_group.security_group_id]
  execution_role_arn      = module.ecs_iam.execution_role_arn
  task_role_arn           = aws_iam_role.jenkins_ecs.arn
  launch_type             = "EC2"
  enable_execute_command  = true
  memoryReservation       = 256
  fluentbit_plugin_image  = var.system_config["ecs_fluentbit_image"]
  aws_lb_tg_arns = [
    {
      arn = module.admin_alb.tg_https_fwd_arns["jenkins"].arn
      container_port = 8080
      container_name = "jenkins-master"
    },
  ]
  containers              = [
    {
      name = "init-jenkins-master"
      image = var.ecs_config["jenkins-master"]["image"]["default"]
      privileged              = true
      essential               = false
      user             = "0"
      command          = ["bash", "/usr/local/bin/bootstrap.sh"]
      environment = [
        {
          name = "GITHUB_ID"
          value = var.system_config["github"]["id"]
        },
        {
          name = "GITHUB_TOKEN"
          value = var.system_config["github"]["token"]
        },
        {
          name = "GIT_BRANCH"
          value = var.system_config["jenkins"]["branch"]
        },
      ]
      mountPoints = [
        {
          containerPath = "/mnt/efs/src-jenkins"
          sourceVolume  = "src-jenkins"
        }
      ]
    },
    {
      name = "jenkins-master"
      image = var.ecs_config["jenkins-master"]["image"]["default"]
      privileged              = true
      portMappings = [
        {
            ContainerPort = 8080
        },
        {
            ContainerPort = 50000
        }
      ]
      environment = [
        {
            name = "GOOGLE_CLIENT_ID"
            value = var.system_config["google_auth"]["client_id"] 
        },
        {
            name = "GOOGLE_CLIENT_SECRET"
            value = var.system_config["google_auth"]["client_secret"]
        },
        {
            name = "GOOGLE_APP_DOMAIN"
            value = var.system_config["gcp_login_dns"]
        },
        {
          name = "GITHUB_ID"
          value = var.system_config["github"]["id"]
        },
        {
          name = "GITHUB_TOKEN"
          value = var.system_config["github"]["token"]
        },
        {
          name = "GIT_BRANCH"
          value = var.system_config["jenkins"]["branch"]
        },
        {
          name = "MAIN_DNS"
          value = var.system_config["main_dns_domain"]
        },
      ]
      mountPoints = [
        {
          containerPath = "/var/jenkins_home"
          sourceVolume  = aws_ebs_volume.jenkins_master.tags_all["Name"]
        },
        {
          containerPath = "/mnt/efs/src-jenkins"
          sourceVolume  = "src-jenkins"
        }
      ]
      dependsOn = [
        {
          containerName = "init-jenkins-master"
          condition = "SUCCESS"
        }
      ]
    }
  ]
  volumes = [
    {
      name = aws_ebs_volume.jenkins_master.tags_all["Name"]
      docker_volume_configuration = {
        scope = "shared"
        autoprovision = false
        driver = "rexray/ebs"
      }
    },
    {
      name = "src-jenkins"
      efs_volume_configuration = {
        file_system_id = module.platform_efs.efs_id
        access_point_id = module.platform_efs.access_point_ids["src-jenkins"].id
      }
    },
  ]
  placementConstraints = [
    {
      expression = "attribute:ecs.availability-zone == ${var.system_config["aws_default_region"]}${local.aws_zones_indexes[0]}"
      type = "memberOf"
    }
  ]
  discovery_namespace = {
    enable = true
    id = aws_service_discovery_private_dns_namespace.ecs.id
  }
  resource_config = var.ecs_config["jenkins-master"]
  dns_private_loki = local.dns_private_loki
}

resource aws_ebs_volume  jenkins_master {
  availability_zone = "${var.system_config["aws_default_region"]}${local.aws_zones_indexes[0]}"
  size              = var.ebs_config["jenkins-master"]["volume_size"]
  encrypted = true
  type = var.ebs_config["jenkins-master"]["volume_type"]
  tags = {
    Name = "ecs-jenkins-master"
  }
}

# jenkin worker
module  jenkin_worker {
  source = "../components/ecs-service"
  count                   = var.asg_config["ecs-jenkins"]["capacity"]
  cluster_id              = aws_ecs_cluster.admin.id
  app_name                = "jenkins-worker-${count.index}"
  subnet_ids              = module.vpc.subnet_private_with_nat_ids
  security_group_ids      = [module.ecs_security_group.security_group_id]
  execution_role_arn      = module.ecs_iam.execution_role_arn
  task_role_arn           = aws_iam_role.jenkins_ecs.arn
  launch_type             = "EC2"
  enable_execute_command  = true
  memoryReservation       = 256
  fluentbit_plugin_image  = var.system_config["ecs_fluentbit_image"]
  containers              = [
    {
      name = "init-jenkins-worker-${count.index}"
      image = var.ecs_config["jenkins-worker"]["image"]["default"]
      privileged              = true
      essential               = false
      user             = "0"
      command          = ["bash", "/usr/local/bin/bootstrap.sh"]
      environment = [
        {
          name = "GITHUB_ID"
          value = var.system_config["github"]["id"]
        },
        {
          name = "GITHUB_TOKEN"
          value = var.system_config["github"]["token"]
        },
        {
          name = "GIT_BRANCH"
          value = var.system_config["jenkins"]["branch"]
        },
      ]
      mountPoints = [
        {
          containerPath = "/mnt/efs/src-jenkins"
          sourceVolume  = "src-jenkins"
        },
        {
          containerPath = "/var/run/docker.sock"
          sourceVolume  = "docker-socket"
        },
      ]
    },
    {
      name = "jenkins-worker-${count.index}"
      image = var.ecs_config["jenkins-worker"]["image"]["default"]
      privileged              = true
      environment = [
        {
          name = "JENKINS_AGENT_WORKDIR"
          value = "/var/jenkins_home"
        },
        {
          name = "JENKINS_URL"
          value = "http://jenkins-master.${local.ecs_private_dns}:8080"
        },
        {
          name = "JENKINS_AGENT_NAME"
          value = count.index == 0 ? "worker${count.index + 1}" : "worker-chain"
        },
        {
            name = "JENKINS_SECRET"
            value = count.index == 0 ? var.system_config["jenkins"]["secret"] : var.system_config["jenkins"]["secretchain"]
        },
        {
          name = "GITHUB_ID"
          value = var.system_config["github"]["id"]
        },
        {
          name = "GITHUB_TOKEN"
          value = var.system_config["github"]["token"]
        },
        {
          name = "GIT_BRANCH"
          value = var.system_config["jenkins"]["branch"]
        },
      ]
      mountPoints = [
        {
          containerPath = "/var/jenkins_home"
          sourceVolume  = aws_ebs_volume.jenkins_worker[0].tags_all["Name"]
        },
        {
          containerPath = "/mnt/efs/src-jenkins"
          sourceVolume  = "src-jenkins"
        },
        {
          containerPath = "/var/run/docker.sock"
          sourceVolume  = "docker-socket"
        },
      ]
      dependsOn = [
        {
          containerName = "init-jenkins-worker-${count.index}"
          condition = "SUCCESS"
        }
      ]
    }
  ]
  volumes = [
    {
      name = aws_ebs_volume.jenkins_worker[count.index].tags_all["Name"]
      docker_volume_configuration = {
        scope = "shared"
        autoprovision = false
        driver = "rexray/ebs"
      }
    },
    {
      name = "src-jenkins"
      efs_volume_configuration = {
        file_system_id = module.platform_efs.efs_id
        access_point_id = module.platform_efs.access_point_ids["src-jenkins"].id
      }
    },
    {
      name = "docker-socket"
      host_path = "/var/run/docker.sock"
    },
  ]
  placementConstraints = [
    {
      expression = "attribute:asg == ${module.asg_admin_jenkins[count.index].ecs_tagid}"
      type = "memberOf"
    }
  ]
  resource_config = count.index == 0 ? var.ecs_config["jenkins-worker"] : var.ecs_config["jenkins-chainworker"]
  dns_private_loki = local.dns_private_loki
}

resource aws_ebs_volume  jenkins_worker {
  count = var.asg_config["ecs-jenkins"]["capacity"]
  availability_zone = "${var.system_config["aws_default_region"]}${local.aws_zones_indexes[count.index % 3]}"
  size              = var.ebs_config["jenkins-worker"]["volume_size"]
  encrypted = true
  type = var.ebs_config["jenkins-worker"]["volume_type"]
  tags = {
    Name = "ecs-jenkins-worker-${count.index}"
  }
}

# prometheus
module  monitor_prometheus {
  source = "../components/ecs-service"
  count                   = var.asg_config["ecs-monitors"]["capacity"]
  cluster_id              = aws_ecs_cluster.admin.id
  app_name                = "monitor-prometheus-${count.index}"
  subnet_ids              = module.vpc.subnet_private_with_nat_ids
  security_group_ids      = [module.ecs_security_group.security_group_id]
  execution_role_arn      = module.ecs_iam.execution_role_arn
  task_role_arn           = aws_iam_role.jenkins_ecs.arn
  launch_type             = "EC2"
  enable_execute_command  = true
  memoryReservation       = 256
  fluentbit_plugin_image  = var.system_config["ecs_fluentbit_image"]
  aws_lb_tg_arns = [
    {
      arn            = module.admin_alb.tg_https_fwd_arns["prometheus"].arn
      container_port = 9090
      container_name =  "monitor-prometheus-${count.index}"
    },
    {
      arn            = module.private_alb.tg_http_fwd_arns["prometheus"].arn
      container_port = 9090
      container_name =  "monitor-prometheus-${count.index}"
    }
  ]
  containers              = [
    {
      name = "monitor-prometheus-${count.index}"
      image = var.ecs_config["monitor-prometheus"]["image"]["default"]
      command              = [
        "--config.file=/etc/prometheus/prometheus.yml",
        "--storage.tsdb.path=/prometheus",
        "--web.console.libraries=/usr/share/prometheus/console_libraries",
        "--web.console.templates=/usr/share/prometheus/consoles",
        "--web.enable-lifecycle",
        "--web.enable-admin-api"
      ]
      portMappings = [
        {
            ContainerPort = 9090
        },
      ]
      mountPoints = [
        {
          containerPath = "/prometheus"
          sourceVolume  = aws_ebs_volume.monitor_prometheus[count.index].tags_all["Name"]
        },
      ]
    }
  ]
  volumes = [
    {
      name = aws_ebs_volume.monitor_prometheus[count.index].tags_all["Name"]
      docker_volume_configuration = {
        scope = "shared"
        autoprovision = false
        driver = "rexray/ebs"
      }
    },
  ]
  placementConstraints = [
    {
      expression = "attribute:asg == ${module.asg_admin_monitors[count.index].ecs_tagid}"
      type = "memberOf"
    }
  ]
  resource_config = var.ecs_config["monitor-prometheus"]
  dns_private_loki = local.dns_private_loki
}

resource aws_ebs_volume monitor_prometheus {
  count = var.asg_config["ecs-monitors"]["capacity"]
  availability_zone = "${var.system_config["aws_default_region"]}${local.aws_zones_indexes[count.index % 3]}"
  size              = var.ebs_config["monitor-prometheus"]["volume_size"]
  encrypted = true
  type = var.ebs_config["monitor-prometheus"]["volume_type"]
  tags = {
    Name = "monitor-prometheus-${count.index}"
  }
}

# grafana
module  monitor_grafana {
  source = "../components/ecs-service"
  count                   = var.asg_config["ecs-monitors"]["capacity"]
  cluster_id              = aws_ecs_cluster.admin.id
  app_name                = "monitor-grafana-${count.index}"
  subnet_ids              = module.vpc.subnet_private_with_nat_ids
  security_group_ids      = [module.ecs_security_group.security_group_id]
  execution_role_arn      = module.ecs_iam.execution_role_arn
  task_role_arn           = aws_iam_role.jenkins_ecs.arn
  launch_type             = "EC2"
  enable_execute_command  = true
  memoryReservation       = 256
  fluentbit_plugin_image  = var.system_config["ecs_fluentbit_image"]
  aws_lb_tg_arns = [
    {
      arn            = module.admin_alb.tg_https_fwd_arns["grafana"].arn
      container_port = 3000
      container_name =  "monitor-grafana-${count.index}"
    }
  ]
  containers              = [
    {
      name = "monitor-grafana-${count.index}"
      image = var.ecs_config["monitor-grafana"]["image"]["default"]
      portMappings = [
        {
            ContainerPort = 3000
        },
      ]
      environment = [
        {
          name = "GF_SECURITY_ADMIN_PASSWORD"
          value = var.system_config["grafana"]["admin_password"]
        },
        {
          name = "GF_AUTH_GOOGLE_CLIENT_ID"
          value = var.system_config["grafana"]["google_id"]
        },
        {
          name = "GF_AUTH_GOOGLE_CLIENT_SECRET"
          value = var.system_config["grafana"]["google_secret"]
        },
        {
          name = "GF_SERVER_ROOT_URL"
          value = "https://${local.dns_monitor}"
        },
        {
          name = "GF_AUTH_GOOGLE_ALLOWED_DOMAINS"
          value = var.system_config["gcp_login_dns"]
        }
      ]
      mountPoints = [
        {
          containerPath = "/var/lib/grafana"
          sourceVolume  = aws_ebs_volume.monitor_grafana[count.index].tags_all["Name"]
        },
      ]
    }
  ]
  volumes = [
    {
      name = aws_ebs_volume.monitor_grafana[count.index].tags_all["Name"]
      docker_volume_configuration = {
        scope = "shared"
        autoprovision = false
        driver = "rexray/ebs"
      }
    },
  ]
  placementConstraints = [
    {
      expression = "attribute:asg == ${module.asg_admin_monitors[count.index].ecs_tagid}"
      type = "memberOf"
    }
  ]
  resource_config = var.ecs_config["monitor-grafana"]
  dns_private_loki = local.dns_private_loki
}

resource aws_ebs_volume monitor_grafana {
  count = var.asg_config["ecs-monitors"]["capacity"]
  availability_zone = "${var.system_config["aws_default_region"]}${local.aws_zones_indexes[count.index % 3]}"
  size              = var.ebs_config["monitor-grafana"]["volume_size"]
  encrypted = true
  type = var.ebs_config["monitor-grafana"]["volume_type"]
  tags = {
    Name = "monitor-grafana-${count.index}"
  }
}

# loki
module  monitor_loki {
  source = "../components/ecs-service"
  count                   = var.asg_config["ecs-monitors"]["capacity"]
  cluster_id              = aws_ecs_cluster.admin.id
  app_name                = "monitor-loki-${count.index}"
  subnet_ids              = module.vpc.subnet_private_with_nat_ids
  security_group_ids      = [module.ecs_security_group.security_group_id]
  execution_role_arn      = module.ecs_iam.execution_role_arn
  task_role_arn           = aws_iam_role.jenkins_ecs.arn
  launch_type             = "EC2"
  enable_execute_command  = true
  memoryReservation       = 256
  fluentbit_plugin_image  = var.system_config["ecs_fluentbit_image"]
  aws_lb_tg_arns = [
    {
      arn            = module.private_alb.tg_http_fwd_arns["loki"].arn
      container_port = 3100
      container_name =  "monitor-loki-${count.index}"
    }
  ]
  containers              = [
    {
      name = "monitor-loki-${count.index}"
      image = var.ecs_config["monitor-loki"]["image"]["default"]
      command = ["-config.file=/etc/loki/config.yaml"]
      portMappings = [
        {
            ContainerPort = 3100
        },
      ]
      mountPoints = [
        {
          containerPath = "/loki"
          sourceVolume  = aws_ebs_volume.monitor_loki[count.index].tags_all["Name"]
        },
      ]
    }
  ]
  volumes = [
    {
      name = aws_ebs_volume.monitor_loki[count.index].tags_all["Name"]
      docker_volume_configuration = {
        scope = "shared"
        autoprovision = false
        driver = "rexray/ebs"
      }
    },
  ]
  placementConstraints = [
    {
      expression = "attribute:asg == ${module.asg_admin_monitors[count.index].ecs_tagid}"
      type = "memberOf"
    }
  ]
  resource_config = var.ecs_config["monitor-loki"]
  dns_private_loki = local.dns_private_loki
}

resource aws_ebs_volume monitor_loki {
  count = var.asg_config["ecs-monitors"]["capacity"]
  availability_zone = "${var.system_config["aws_default_region"]}${local.aws_zones_indexes[count.index % 3]}"
  size              = var.ebs_config["monitor-loki"]["volume_size"]
  encrypted = true
  type = var.ebs_config["monitor-loki"]["volume_type"]
  tags = {
    Name = "monitor-loki-${count.index}"
  }
}