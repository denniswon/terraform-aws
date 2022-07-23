locals {
  enable_zones = { "1a" = true, "1b" = true, "1c" = true }
  create_internet_gateway = var.has_public_subnet || var.has_private_subnet_with_nat ? 1 : 0
  
  # zone_1a
  create_public_subnet_zone_1a = (var.has_public_subnet || var.has_private_subnet_with_nat) && local.enable_zones["1a"] ? 1 : 0
  create_private_subnet_zone_1a = var.has_private_subnet && local.enable_zones["1a"] ? 1 : 0
  create_private_subnet_with_nat_zone_1a = var.has_private_subnet_with_nat && local.enable_zones["1a"] ? 1 : 0

  # zone_1b
  create_public_subnet_zone_1b = (var.has_public_subnet || var.has_private_subnet_with_nat) && local.enable_zones["1b"] ? 1 : 0
  create_private_subnet_zone_1b = var.has_private_subnet && local.enable_zones["1b"] ? 1 : 0
  create_private_subnet_with_nat_zone_1b = var.has_private_subnet_with_nat && local.enable_zones["1b"] ? 1 : 0

  # zone_1c
  create_public_subnet_zone_1c = (var.has_public_subnet || var.has_private_subnet_with_nat) && local.enable_zones["1c"] ? 1 : 0
  create_private_subnet_zone_1c = var.has_private_subnet && local.enable_zones["1c"] ? 1 : 0
  create_private_subnet_with_nat_zone_1c = var.has_private_subnet_with_nat && local.enable_zones["1c"] ? 1 : 0
}

resource aws_vpc vpc {
  cidr_block           = "${var.cidr_prefix}.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

# Internet Gateway
resource aws_internet_gateway internet_gateway {
  count  = local.create_internet_gateway
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.vpc_name
  }
}

# EIP
resource aws_eip eip_1a {
  count    = local.create_private_subnet_with_nat_zone_1a
  vpc      = true
  tags = {
    Name = "${var.vpc_name}-nat-1a"
  }
}

resource aws_eip eip_1b {
  count    = local.create_private_subnet_with_nat_zone_1b
  vpc      = true
  tags = {
    Name = "${var.vpc_name}-nat-1b"
  }
}

resource aws_eip eip_1c {
  count    = local.create_private_subnet_with_nat_zone_1c
  vpc      = true
  tags = {
    Name = "${var.vpc_name}-nat-1c"
  }
}

# NAT Gateway
resource aws_nat_gateway nat_gateway_1a {
  count         = local.create_private_subnet_with_nat_zone_1a
  allocation_id = aws_eip.eip_1a[0].id
  subnet_id     = aws_subnet.subnet_public_1a[0].id
  tags = {
    Name = "${var.vpc_name}-private-1a"
  }
}

resource aws_nat_gateway nat_gateway_1b {
  count         = local.create_private_subnet_with_nat_zone_1b
  allocation_id = aws_eip.eip_1b[0].id
  subnet_id     = aws_subnet.subnet_public_1b[0].id
  tags = {
    Name = "${var.vpc_name}-private-1b"
  }
}

resource aws_nat_gateway nat_gateway_1c {
  count         = local.create_private_subnet_with_nat_zone_1c
  allocation_id = aws_eip.eip_1c[0].id
  subnet_id     = aws_subnet.subnet_public_1c[0].id
  tags = {
    Name = "${var.vpc_name}-private-1c"
  }
}

# Public Subnets
resource aws_subnet subnet_public_1a {
  count                   = local.create_public_subnet_zone_1a
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.cidr_prefix}.21.0/24"
  availability_zone       = "${var.aws_default_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-1a"
  }
}

resource aws_subnet subnet_public_1b {
  count                   = local.create_public_subnet_zone_1b
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.cidr_prefix}.22.0/24"
  availability_zone       = "${var.aws_default_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-1b"
  }
}

resource aws_subnet subnet_public_1c {
  count                   = local.create_public_subnet_zone_1c
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.cidr_prefix}.23.0/24"
  availability_zone       = "${var.aws_default_region}c"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-1c"
  }
}

resource aws_default_route_table public {
  count                  = local.create_internet_gateway
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway[0].id
  }
  tags = {
    Name = "${var.vpc_name}-public"
  }
  lifecycle {
    ignore_changes = [route]
  }
}

# Private Subnets
resource aws_subnet subnet_private_1a {
  count                   = local.create_private_subnet_zone_1a
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.cidr_prefix}.31.0/24"
  availability_zone       = "${var.aws_default_region}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.vpc_name}-private-1a"
  }
}

resource aws_subnet subnet_private_1b {
  count                   = local.create_private_subnet_zone_1b
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.cidr_prefix}.32.0/24"
  availability_zone       = "${var.aws_default_region}b"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.vpc_name}-private-1b"
  }
}

resource aws_subnet subnet_private_1c {
  count                   = local.create_private_subnet_zone_1c
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.cidr_prefix}.33.0/24"
  availability_zone       = "${var.aws_default_region}c"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.vpc_name}-private-1c"
  }
}

resource aws_route_table subnet_private {
  count                   = var.has_private_subnet ? 1 : 0
  vpc_id                  = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-private"
  }
}

resource aws_route_table_association subnet_private_1a {
  count          = local.create_private_subnet_zone_1a
  subnet_id      = aws_subnet.subnet_private_1a[0].id
  route_table_id = aws_route_table.subnet_private[0].id
}

resource aws_route_table_association subnet_private_1b {
  count          = local.create_private_subnet_zone_1b
  subnet_id      = aws_subnet.subnet_private_1b[0].id
  route_table_id = aws_route_table.subnet_private[0].id
}

resource aws_route_table_association subnet_private_1c {
  count          = local.create_private_subnet_zone_1c
  subnet_id      = aws_subnet.subnet_private_1c[0].id
  route_table_id = aws_route_table.subnet_private[0].id
}

resource aws_vpc_endpoint s3 {
  count             = var.has_private_subnet ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.aws_default_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.subnet_private[0].id]
}

# Private Subnets with NAT
resource aws_subnet subnet_private_with_nat_1a {
  count                   = local.create_private_subnet_with_nat_zone_1a
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.cidr_prefix}.41.0/24"
  availability_zone       = "${var.aws_default_region}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.vpc_name}-private-with-nat-1a"
  }
}

resource aws_subnet subnet_private_with_nat_1b {
  count                   = local.create_private_subnet_with_nat_zone_1b
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.cidr_prefix}.42.0/24"
  availability_zone       = "${var.aws_default_region}b"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.vpc_name}-private-with-nat-1b"
  }
}

resource aws_subnet subnet_private_with_nat_1c {
  count                   = local.create_private_subnet_with_nat_zone_1c
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.cidr_prefix}.43.0/24"
  availability_zone       = "${var.aws_default_region}c"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.vpc_name}-private-with-nat-1c"
  }
}

resource aws_route_table subnet_private_with_nat_1a {
  count   = local.create_private_subnet_with_nat_zone_1a
  vpc_id  = aws_vpc.vpc.id
  tags    = {
    Name = "${var.vpc_name}-private-with-nat-1a"
  }
}

resource aws_route_table subnet_private_with_nat_1b {
  count   = local.create_private_subnet_with_nat_zone_1b
  vpc_id  = aws_vpc.vpc.id
  tags    = {
    Name = "${var.vpc_name}-private-with-nat-1b"
  }
}

resource aws_route_table subnet_private_with_nat_1c {
  count   = local.create_private_subnet_with_nat_zone_1c
  vpc_id  = aws_vpc.vpc.id
  tags    = {
    Name = "${var.vpc_name}-private-with-nat-1c"
  }
}

resource aws_route subnet_private_with_nat_1a {
  count                  = local.create_private_subnet_with_nat_zone_1a
  route_table_id         = aws_route_table.subnet_private_with_nat_1a[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1a[0].id
}

resource aws_route subnet_private_with_nat_1b {
  count                  = local.create_private_subnet_with_nat_zone_1b
  route_table_id         = aws_route_table.subnet_private_with_nat_1b[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1b[0].id
}

resource aws_route subnet_private_with_nat_1c {
  count                  = local.create_private_subnet_with_nat_zone_1c
  route_table_id         = aws_route_table.subnet_private_with_nat_1c[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1c[0].id
}

resource aws_route_table_association subnet_private_with_nat_1a {
  count          = local.create_private_subnet_with_nat_zone_1a
  subnet_id      = aws_subnet.subnet_private_with_nat_1a[0].id
  route_table_id = aws_route_table.subnet_private_with_nat_1a[0].id
}

resource aws_route_table_association subnet_private_with_nat_1b {
  count          = local.create_private_subnet_with_nat_zone_1b
  subnet_id      = aws_subnet.subnet_private_with_nat_1b[0].id
  route_table_id = aws_route_table.subnet_private_with_nat_1b[0].id
}

resource aws_route_table_association subnet_private_with_nat_1c {
  count          = local.create_private_subnet_with_nat_zone_1c
  subnet_id      = aws_subnet.subnet_private_with_nat_1c[0].id
  route_table_id = aws_route_table.subnet_private_with_nat_1c[0].id
}

# DB Subnet Group
resource aws_db_subnet_group db_subnet_group {
  count       = var.has_db_subnet_group == true ? 1 : 0
  name        = "${var.vpc_name}-db-subnet"
  subnet_ids  = [
    aws_subnet.subnet_private_1a[0].id,
    aws_subnet.subnet_private_1b[0].id,
    aws_subnet.subnet_private_1c[0].id
  ]
  description = "subnet group for db"
  tags        = {
    Name      = "${var.vpc_name}-db-subnet"
  }
}

resource aws_db_subnet_group db_subnet_public {
  count       = var.has_db_subnet_group == true ? 1 : 0
  name        = "${var.vpc_name}-db-public"
  subnet_ids  = [
    aws_subnet.subnet_public_1a[0].id,
    aws_subnet.subnet_public_1b[0].id,
    aws_subnet.subnet_public_1c[0].id
  ]
  description = "subnet public for db"
  tags        = {
    Name      = "${var.vpc_name}-db-public"
  }
}

resource aws_db_subnet_group db_subnet_nat {
  count       = var.has_db_subnet_group == true ? 1 : 0
  name        = "${var.vpc_name}-db-nat"
  subnet_ids  = [
    aws_subnet.subnet_private_with_nat_1a[0].id,
    aws_subnet.subnet_private_with_nat_1b[0].id,
    aws_subnet.subnet_private_with_nat_1c[0].id
  ]
  description = "subnet nat for db"
  tags        = {
    Name      = "${var.vpc_name}-db-nat"
  }
}

# Elasticache Subnet Group
resource aws_elasticache_subnet_group elasticache_subnet_group {
  count       = var.has_elasticache_subnet_group == true ? 1 : 0
  name        = "${var.vpc_name}-elasticache-subnet"
  subnet_ids  = [
    aws_subnet.subnet_private_1a[0].id,
    aws_subnet.subnet_private_1b[0].id,
    aws_subnet.subnet_private_1c[0].id
  ]
  description = "subnet group for elasticache"
}