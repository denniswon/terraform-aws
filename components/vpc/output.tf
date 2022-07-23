output vpc_id {
  value = aws_vpc.vpc.id
}

output vpc_cidr_block {
  value = aws_vpc.vpc.cidr_block
}

output public_route_table_id {
  value = var.has_public_subnet ? aws_default_route_table.public[0].id : ""
}

output private_route_table_id {
  value = var.has_private_subnet ? aws_route_table.subnet_private[0].id : ""
}

output private_route_table_with_nat_ids {
  value = var.has_private_subnet_with_nat ? [
    aws_route_table.subnet_private_with_nat_1a[0].id,
    aws_route_table.subnet_private_with_nat_1b[0].id,
    aws_route_table.subnet_private_with_nat_1c[0].id
  ] : []
}

output subnet_public_ids {
  value = var.has_public_subnet ? [
    aws_subnet.subnet_public_1a[0].id,
    aws_subnet.subnet_public_1b[0].id,
    aws_subnet.subnet_public_1c[0].id
  ] : []
}

output subnet_private_ids {
  value = var.has_private_subnet ? [
    aws_subnet.subnet_private_1a[0].id,
    aws_subnet.subnet_private_1b[0].id,
    aws_subnet.subnet_private_1c[0].id
  ] : []
}

output subnet_private_with_nat_ids {
  value = var.has_private_subnet_with_nat ? [
    aws_subnet.subnet_private_with_nat_1a[0].id,
    aws_subnet.subnet_private_with_nat_1b[0].id,
    aws_subnet.subnet_private_with_nat_1c[0].id
  ] : []
}

output db_subnet_private_id {
  value = var.has_db_subnet_group == true ? aws_db_subnet_group.db_subnet_group[0].id : ""
}

output db_subnet_public_id {
  value = var.has_db_subnet_group == true ? aws_db_subnet_group.db_subnet_public[0].id : ""
}

output db_subnet_nat_id {
  value = var.has_db_subnet_group == true ? aws_db_subnet_group.db_subnet_nat[0].id : ""
}

output elasticache_subnet_group_id {
  value = var.has_elasticache_subnet_group == true ? aws_elasticache_subnet_group.elasticache_subnet_group[0].id : ""
}