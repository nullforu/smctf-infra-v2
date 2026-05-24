output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "protected_subnet_ids" {
  value = module.network.protected_subnet_ids
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "backend_ecs_cluster_name" {
  value = module.ecs.backend_ecs_cluster_name
}

output "backend_ecs_service_name" {
  value = module.ecs.backend_ecs_service_name
}

output "control_plane_private_ip" {
  value = module.sbxcluster.control_plane_private_ip
}

output "bastion_instance_id" {
  value = module.bastion.instance_id
}

output "bastion_private_ip" {
  value = module.bastion.private_ip
}

output "worker_public_ips" {
  value = module.sbxcluster.worker_public_ips
}

output "rds_endpoint" {
  value = module.db.rds_endpoint
}

output "redis_primary_endpoint" {
  value = module.db.redis_primary_endpoint
}

output "s3_challenge_bucket" {
  value = module.storage.s3_bucket_name
}

output "ecr_repository_urls" {
  value = module.storage.ecr_repository_urls
}

output "ecr_repository_arns" {
  value = module.storage.ecr_repository_arns
}
