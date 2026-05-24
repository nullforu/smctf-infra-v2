output "control_plane_private_ip" {
  value = var.enable_sandboxd ? aws_instance.control_plane[0].private_ip : null
}

output "control_plane_sg_id" {
  value = var.enable_sandboxd ? aws_security_group.control_plane[0].id : null
}

output "worker_public_ips" {
  value = var.enable_sandboxd ? aws_instance.worker[*].public_ip : []
}
