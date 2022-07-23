resource aws_ecr_repository ecr {
  for_each              = toset(var.system_config["ecr_repositories"])
  name                  = each.key
  image_tag_mutability  = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}