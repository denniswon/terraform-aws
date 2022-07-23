module "bootstrap_chain_validator" {
  source                 = "../components/ecs-service"
  cluster_id             = aws_ecs_cluster.admin.id
  app_name               = "bootstrap-chain-validator"
  subnet_ids             = module.vpc.subnet_private_with_nat_ids
  security_group_ids     = [module.ecs_security_group.security_group_id]
  execution_role_arn     = module.ecs_iam.execution_role_arn
  task_role_arn          = module.ecs_iam.execution_role_arn
  launch_type            = "FARGATE"
  enable_execute_command = true
  memoryReservation      = 256
  fluentbit_plugin_image = var.system_config["ecs_fluentbit_image"]
  containers = [
    {
      name      = "bootstrap-chain-validator"
      image     = var.ecs_config["chain"]["image"]["default"]
      command   = [<<EOF
      gaiad testnet --chain-id $${CHAIN_ID} --v $${NUMS_OF_VALIDATOR}
      --output-dir /genesis --starting-ip-address $${BOOTSTRAP_IP_ADDRESS} 
      --keyring-backend $${KEYRING_BACKEND} --minimum-gas-prices $${MIN_GAS_PRICE}
      --node-dir-prefix 'validator'
      EOF
      ]
      essential = false
      environment = [
        {
          name  = "NUMS_OF_VALIDATOR"
          value = "4"
        },
        {
          name  = "KEYRING_BACKEND"
          value = "test"
        },
        {
          name  = "CHAIN_ID"
          value = "interopera"
        },
        {
          name  = "MIN_GAS_PRICE"
          value = "0uatom"
        },
        {
            name = "BOOTSTRAP_IP_ADDRESS"
            value = "192.168.10.2"
        }
      ]
      mountPoints = [
        {
          containerPath = "/genesis"
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
  resource_config  = var.ecs_config["chain"]
  dns_private_loki = local.dns_private_loki
}