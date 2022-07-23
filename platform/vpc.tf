module vpc {
  source = "../components/vpc"
  has_public_subnet            = true
  has_private_subnet           = true
  has_private_subnet_with_nat  = true
  has_db_subnet_group          = true
  has_elasticache_subnet_group = true
  cidr_prefix                  = var.system_config["vpc_cidr_prefix"]
  vpc_name                     = var.system_config["aws_vpc_name"]
  aws_default_region           = var.system_config["aws_default_region"]
}