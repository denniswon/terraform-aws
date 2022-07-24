module "bootstrap_chain_validator" {
  source                 = "../components/ecs-service"
  cluster_id             = aws_ecs_cluster.admin.id
  app_name               = "bootstrap-chain-validator"
  subnet_ids             = []
  security_group_ids     = []
  execution_role_arn     = module.ecs_iam.execution_role_arn
  task_role_arn          = module.ecs_iam.execution_role_arn
  launch_type            = "EC2"
  enable_execute_command = true
  memoryReservation      = 256
  fluentbit_plugin_image = var.system_config["ecs_fluentbit_image"]
  containers = [
    {
      name = "is-empty-bootrap"
      image = var.ecs_config["bootstrap-chain-validator"]["image"]["ecs-utils"]
      essential               = false
      user             = "0"
      command          = ["bash", "/app/is-empty-bootrap.sh"]
      environment = [
        {
          name = "NUMS_OF_VALIDATOR"
          value = tostring(length(var.system_config["chain_gaia"]["VALIDATOR_STATIC_IPS"]))
        },
      ]
      mountPoints = [
        {
            containerPath = "/mnt/efs/chain-bootstrap"
            sourceVolume  = "chain-bootstrap"
        }
      ]
    },
    {
      name      = "bootstrap-chain-validator"
      image     = var.ecs_config["bootstrap-chain-validator"]["image"]["default"]
      command   = [
        "gaiad", "testnet", "--chain-id", "${var.system_config["chain_gaia"]["CHAIN_ID"]}", "--v", "${tostring(length(var.system_config["chain_gaia"]["VALIDATOR_STATIC_IPS"]))}",
        "--output-dir", "/mnt/efs/chain-bootstrap", "--starting-ip-address", "${var.system_config["chain_gaia"]["BOOTSTRAP_IP_PREFIX"]}.0",
        "--keyring-backend", "${var.system_config["chain_gaia"]["KEYRING_BACKEND"]}", "--minimum-gas-prices",  "${var.system_config["chain_gaia"]["MIN_GAS_PRICE"]}",
        "--node-dir-prefix", "validator"
      ]
      essential = false
      mountPoints = [
        {
          containerPath = "/mnt/efs/chain-bootstrap"
          sourceVolume  = "chain-bootstrap"
        }
      ]
      dependsOn = [
        {
            containerName = "is-empty-bootrap"
            condition = "SUCCESS"
        }
      ]
    },
    {
      name = "update-validator-ip"
      image = var.ecs_config["bootstrap-chain-validator"]["image"]["ecs-utils"]
      essential               = false
      user             = "0"
      command          = ["tail", "-f", "/dev/null"]
      environment = [
        {
          name = "VALIDATOR_STATIC_IPS"
          value = join(",", var.system_config["chain_gaia"]["VALIDATOR_STATIC_IPS"])
        },
        {
          name = "BOOTSTRAP_IP_PREFIX"
          value = var.system_config["chain_gaia"]["BOOTSTRAP_IP_PREFIX"]
        },
      ]
      mountPoints = [
        {
            containerPath = "/mnt/efs/chain-bootstrap"
            sourceVolume  = "chain-bootstrap"
        }
      ]
    },
  ]
  volumes = [
    {
      name = "chain-bootstrap"
      efs_volume_configuration = {
        file_system_id  = module.platform_efs.efs_id
        access_point_id = module.platform_efs.access_point_ids["chain-bootstrap"].id
      }
    },
  ]
  placementConstraints = [
    {
        expression = "attribute:asg == ${module.asg_admin_monitors[0].ecs_tagid}"
        type       = "memberOf"
    }
  ]
  resource_config  = var.ecs_config["bootstrap-chain-validator"]
  dns_private_loki = local.dns_private_loki
}