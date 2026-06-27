output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "bastion_instance_profile_name" {
  value = var.enable_bastion ? aws_iam_instance_profile.bastion[0].name : null
}
