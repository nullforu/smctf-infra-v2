variable "name_prefix" { type = string }
variable "tags" { type = map(string) }

variable "s3_bucket_arn" { type = string }
variable "backend_image" { type = string }
variable "ecr_repository_names" { type = list(string) }

variable "enable_sandboxd" { type = bool }
variable "worker_instance_profile_policy_arns" { type = list(string) }
variable "control_plane_instance_profile_policy_arns" { type = list(string) }

variable "enable_bastion" { type = bool }
variable "bastion_instance_profile_policy_arns" { type = list(string) }
