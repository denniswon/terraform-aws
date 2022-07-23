variable ami_id {}
variable asg_name {}
variable instance_type {}
variable security_group_ids {}
variable subnet_ids {}
variable ssm_log_s3_arn {}
variable ssm_decrypt_key_arn {}
variable root_volume_size {}
variable ecs_cluster { default = "" }
variable workspace_snapshot_s3_name { default = "" }
variable bootstrap_src { default = "userdata-ec2" }
variable root_device_name { default = "/dev/xvda" }
variable key_pair { default = "" }
variable additional_user_data { default = "" }
variable instance_capacity { default     = 1 }
variable health_check_grace_period { default     = 300 }
variable health_check_type { default     = "EC2" }
variable target_group_arns { default     = [] }
variable load_balancers { default     = [] }
variable default_cooldown { default     = 300 }
variable termination_policies { default     = ["OldestLaunchTemplate", "OldestInstance"] }
variable protect_from_scale_in { default     = true }
variable disable_api_termination { default     = false }
variable associate_public_ip { default = false }
variable update_default_version { default     = true }
variable additional_tags { default = {} }
variable suspended_processes { default = [] }
variable efs_id { default = "" }
variable efs_accesspoint { default = "" }