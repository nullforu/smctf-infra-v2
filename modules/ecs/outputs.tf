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
