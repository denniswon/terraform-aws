variable bucket_name {}
variable bucket_versioning { default     = false }
variable object_lock_configuration { default     = {} }
variable cors_rule { default     = [] }
variable acl_config { default = null }
variable cf_origin_access_identity { 
    default = {
        enable = false
        arn = null
    }
}
variable target_log_bucket { default = "" }