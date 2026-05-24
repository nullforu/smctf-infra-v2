variable "name_prefix" { type = string }
variable "tags" { type = map(string) }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }

variable "enable_sandboxd" { type = bool }

variable "worker_node_count" { type = number }
variable "worker_node_instance_type" { type = string }
variable "worker_node_ami_id" { type = string }
variable "worker_node_key_name" { type = string }
variable "worker_node_root_volume_size" { type = number }

variable "control_plane_instance_type" { type = string }
variable "control_plane_ami_id" { type = string }
variable "control_plane_key_name" { type = string }
variable "control_plane_root_volume_size" { type = number }

variable "worker_public_port_range" {
  type = object({
    from = number
    to   = number
  })
}

variable "backend_to_control_plane_port" { type = number }
variable "control_plane_to_worker_port" { type = number }

variable "backend_security_group_id" { type = string }
variable "bastion_security_group_id" {
  type    = string
  default = null
}

variable "worker_instance_profile_name" { type = string }
variable "control_plane_instance_profile_name" { type = string }
