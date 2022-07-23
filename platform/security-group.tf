module "packer_security_group" {
  source                = "../components/security-group"
  vpc_id                = module.vpc.vpc_id
  group_name            = "packer-builder"
  default_ingress_cidrs = ["0.0.0.0/0"]
}

module "ecs_security_group" {
  source                = "../components/security-group"
  vpc_id                = module.vpc.vpc_id
  group_name            = "ecs-sg"
  default_ingress_cidrs = [module.vpc.vpc_cidr_block]
}

module "efs_security_group" {
  source                = "../components/security-group"
  vpc_id                = module.vpc.vpc_id
  group_name            = "efs-sg"
  default_ingress_cidrs = [module.vpc.vpc_cidr_block]
}

module "admin_alb_security_group" {
  source     = "../components/security-group"
  vpc_id     = module.vpc.vpc_id
  group_name = "admin-alb-sg"
  default_ingress_cidrs = ["0.0.0.0/0"]
}

module "private_alb_security_group" {
  source                = "../components/security-group"
  vpc_id                = module.vpc.vpc_id
  group_name            = "private-alb-sg"
  default_ingress_cidrs = [module.vpc.vpc_cidr_block]
}