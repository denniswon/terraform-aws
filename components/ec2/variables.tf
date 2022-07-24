variable "instance_type" {}
variable "instance_name" {}
variable "security_group_ids" {}
variable "subnet_ids" {}
variable ami_id {}
variable "has_public_ip" { default     = false }
variable "role" {}
variable "tag_additional" { default = {} }
variable "placement_group" { default     = "" }
variable "instance_count" { default     = 1 }
variable "userdata" { default     = "" }
variable "root_volume_type" { default     = null }
variable "root_volume_size" {}
variable "root_iops" { default     = null }
variable "root_throughput" { default     = null }
variable "ebs_block_device" { default     = [] }
variable "root_encrypted" { default     = false }
variable "private_ip" { default     = null }
variable "ebs_optimized" { default     = true }
variable "disable_api_termination" { default     = true }
variable additional_user_data { default = "" }
variable ecs_cluster { default = "" }