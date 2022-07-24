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
      name      = "bootstrap-chain-validator"
      image     = var.ecs_config["bootstrap-chain-validator"]["image"]["default"]
      command   = [
        "gaiad", "testnet", "--chain-id", "${var.system_config["chain_gaia"]["CHAIN_ID"]}", "--v", "${var.system_config["chain_gaia"]["NUMS_OF_VALIDATOR"]}",
        "--output-dir", "/genesis", "--starting-ip-address", "${var.system_config["chain_gaia"]["BOOTSTRAP_IP_ADDRESS"]}",
        "--keyring-backend", "${var.system_config["chain_gaia"]["KEYRING_BACKEND"]}", "--minimum-gas-prices",  "${var.system_config["chain_gaia"]["MIN_GAS_PRICE"]}",
        "--node-dir-prefix", "validator"
      ]
      essential = false
    #   mountPoints = [
    #     {
    #       containerPath = "/genesis"
    #       sourceVolume  = "chain-bootstrap"
    #     }
    #   ]
    },
  ]
  volumes = [
    # {
    #   name = "chain-bootstrap"
    #   efs_volume_configuration = {
    #     file_system_id  = module.platform_efs.efs_id
    #     access_point_id = module.platform_efs.access_point_ids["chain-bootstrap"].id
    #   }
    # },
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