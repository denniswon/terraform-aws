variable alb_name {}
variable vpc_id {}
variable subnet_ids {}
variable alb_log_bucket {}
variable security_group_ids { default = [] }
variable alb_type { default = "application" }
variable default_certificate_arn { default = "" }
variable additional_certificate_arns { default = [] }
variable if_internal { default = false }
variable webaclv2 {
    default = {
        enabled = false
        arn = ""
    }
}

# port http & https config
variable port_http_fwd { default = {} }
variable port_https_fwd { default = {} }

# port grpc config
variable port_grpc_fwd { default = {} }

# nlb port config
variable port_nlb_fwd { default = 0 }
variable port_nlbs_fwd { default = 0 }
variable nlb_target_type { default = "ip" }