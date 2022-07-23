resource aws_service_discovery_service this {
  count = var.discovery_namespace.enable ? 1 : 0
  name = var.app_name

  dns_config {
    namespace_id = var.discovery_namespace.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
