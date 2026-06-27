variable "name_prefix" { type = string }
variable "tags" { type = map(string) }

variable "s3_bucket_arn" { type = string }

variable "enable_bastion" { type = bool }
variable "bastion_instance_profile_policy_arns" { type = list(string) }
