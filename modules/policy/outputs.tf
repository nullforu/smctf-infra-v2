output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "worker_instance_profile_name" {
  value = var.enable_sandboxd ? aws_iam_instance_profile.worker[0].name : null
}

output "control_plane_instance_profile_name" {
  value = var.enable_sandboxd ? aws_iam_instance_profile.control_plane[0].name : null
}

output "bastion_instance_profile_name" {
  value = var.enable_bastion ? aws_iam_instance_profile.bastion[0].name : null
}
