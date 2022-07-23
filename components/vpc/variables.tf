variable cidr_prefix {}
variable vpc_name {}
variable aws_default_region {}
variable has_public_subnet { default = false }
variable has_private_subnet { default = false }
variable has_private_subnet_with_nat { default = false }
variable has_db_subnet_group { default = false }
variable has_elasticache_subnet_group { default = false }