output "alb_dns_name" {
  value = aws_lb.backend.dns_name
}

output "alb_arn" {
  value = aws_lb.backend.arn
}

output "backend_service_sg_id" {
  value = aws_security_group.backend.id
}

output "backend_ecs_cluster_name" {
  value = aws_ecs_cluster.backend.name
}

output "backend_ecs_service_name" {
  value = aws_ecs_service.backend.name
}

output "invite_bot_service_name" {
  value = var.invite_bot_enabled ? aws_ecs_service.invite_bot[0].name : null
}

output "invite_bot_internal_url" {
  value = var.invite_bot_enabled ? "http://${aws_service_discovery_service.invite_bot[0].name}.${aws_service_discovery_private_dns_namespace.internal[0].name}:8083" : null
}
