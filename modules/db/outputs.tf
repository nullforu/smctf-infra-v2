output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "redis_sg_id" {
  value = aws_security_group.redis.id
}
