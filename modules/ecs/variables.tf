variable "name_prefix" { type = string }
variable "tags" { type = map(string) }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }

variable "alb_ingress_cidrs" { type = list(string) }
variable "acm_certificate_arn" { type = string }

variable "backend_image" { type = string }
variable "backend_cpu" { type = number }
variable "backend_memory" { type = number }
variable "backend_desired_count" { type = number }
variable "backend_min_count" { type = number }
variable "backend_max_count" { type = number }
variable "backend_autoscaling_enabled" { type = bool }
variable "backend_autoscaling_cpu_target" { type = number }
variable "backend_autoscaling_scale_in_cooldown_seconds" { type = number }
variable "backend_autoscaling_scale_out_cooldown_seconds" { type = number }
variable "backend_environment" {
  type    = map(string)
  default = {}
}
variable "backend_log_retention_days" { type = number }
variable "backend_health_check_interval_seconds" { type = number }
variable "backend_health_check_timeout_seconds" { type = number }
variable "backend_health_check_healthy_threshold" { type = number }
variable "backend_health_check_unhealthy_threshold" { type = number }

variable "invite_bot_enabled" {
  type    = bool
  default = false
}
variable "invite_bot_image" {
  type    = string
  default = ""
}
variable "invite_bot_cpu" {
  type    = number
  default = 256
}
variable "invite_bot_memory" {
  type    = number
  default = 512
}
variable "invite_bot_environment" {
  type    = map(string)
  default = {}
}
variable "invite_bot_log_retention_days" {
  type    = number
  default = 14
}

variable "ecs_task_execution_role_arn" { type = string }
variable "ecs_task_role_arn" { type = string }
