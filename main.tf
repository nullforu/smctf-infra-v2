provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }

  backend "s3" {
    bucket         = "terraform-3c70"
    key            = "smctf/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-3c70"
    encrypt        = true
  }
}

locals {
  name_prefix = "${var.project}-${var.environment}"

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.common_tags
  )

  # DB/Redis connection values are derived from the provisioned resources so they
  # are defined once (rds_* vars) instead of being duplicated in backend_environment.
  backend_managed_environment = {
    DB_HOST     = module.db.rds_endpoint
    DB_PORT     = "5432"
    DB_NAME     = var.rds_db_name
    DB_USER     = var.rds_master_username
    DB_PASSWORD = var.rds_master_password
    REDIS_ADDR  = "${module.db.redis_primary_endpoint}:6379"
  }
}

module "network" {
  source = "./modules/network"

  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_cidr               = var.vpc_cidr
  azs                    = var.azs
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  protected_subnet_cidrs = var.protected_subnet_cidrs
  nat_gateway_mode       = var.nat_gateway_mode

  enable_ssm_vpc_endpoints = var.enable_ssm_vpc_endpoints
  enable_s3_vpc_endpoint   = var.enable_s3_vpc_endpoint
}

module "storage" {
  source = "./modules/storage"

  name_prefix = local.name_prefix
  tags        = local.tags

  s3_challenge_bucket_name   = var.s3_challenge_bucket_name
  create_s3_challenge_bucket = var.create_s3_challenge_bucket
  s3_cors_rules              = var.s3_cors_rules

  ecr_repository_names    = var.ecr_repository_names
  create_ecr_repositories = var.create_ecr_repositories
}

module "policy" {
  source = "./modules/policy"

  name_prefix = local.name_prefix
  tags        = local.tags

  s3_bucket_arn = module.storage.s3_bucket_arn

  enable_bastion                       = var.enable_bastion
  bastion_instance_profile_policy_arns = var.bastion_instance_profile_policy_arns
}

module "ecs" {
  source = "./modules/ecs"

  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  alb_ingress_cidrs     = var.alb_ingress_cidrs
  acm_certificate_arn   = var.acm_certificate_arn
  backend_image         = var.backend_image
  backend_cpu           = var.backend_cpu
  backend_memory        = var.backend_memory
  backend_desired_count = var.backend_desired_count
  backend_min_count     = var.backend_min_count
  backend_max_count     = var.backend_max_count

  backend_autoscaling_enabled                    = var.backend_autoscaling_enabled
  backend_autoscaling_cpu_target                 = var.backend_autoscaling_cpu_target
  backend_autoscaling_scale_in_cooldown_seconds  = var.backend_autoscaling_scale_in_cooldown_seconds
  backend_autoscaling_scale_out_cooldown_seconds = var.backend_autoscaling_scale_out_cooldown_seconds
  backend_environment                            = merge(var.backend_environment, local.backend_managed_environment)
  backend_log_retention_days                     = var.backend_log_retention_days
  backend_health_check_interval_seconds          = var.backend_health_check_interval_seconds
  backend_health_check_timeout_seconds           = var.backend_health_check_timeout_seconds
  backend_health_check_healthy_threshold         = var.backend_health_check_healthy_threshold
  backend_health_check_unhealthy_threshold       = var.backend_health_check_unhealthy_threshold
  ecs_task_execution_role_arn                    = module.policy.ecs_task_execution_role_arn
  ecs_task_role_arn                              = module.policy.ecs_task_role_arn

  invite_bot_enabled            = var.invite_bot_enabled
  invite_bot_image              = var.invite_bot_image
  invite_bot_cpu                = var.invite_bot_cpu
  invite_bot_memory             = var.invite_bot_memory
  invite_bot_environment        = var.invite_bot_environment
  invite_bot_log_retention_days = var.invite_bot_log_retention_days
}

module "bastion" {
  source = "./modules/bastion"

  create = var.enable_bastion

  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  subnet_index       = var.bastion_subnet_index

  ami_id           = var.bastion_ami_id
  instance_type    = var.bastion_instance_type
  root_volume_size = var.bastion_root_volume_size
  key_name         = var.bastion_key_name

  instance_profile_name = module.policy.bastion_instance_profile_name
}

module "db" {
  source = "./modules/db"

  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id               = module.network.vpc_id
  protected_subnet_ids = module.network.protected_subnet_ids

  rds_instance_class        = var.rds_instance_class
  rds_allocated_storage_gb  = var.rds_allocated_storage_gb
  rds_multi_az              = var.rds_multi_az
  rds_engine_version        = var.rds_engine_version
  rds_db_name               = var.rds_db_name
  rds_master_username       = var.rds_master_username
  rds_master_password       = var.rds_master_password
  rds_backup_retention_days = var.rds_backup_retention_days
  rds_deletion_protection   = var.rds_deletion_protection

  redis_node_type       = var.redis_node_type
  redis_engine_version  = var.redis_engine_version
  redis_multi_az        = var.redis_multi_az
  redis_num_cache_nodes = var.redis_num_cache_nodes
}

resource "aws_security_group_rule" "backend_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.db.rds_sg_id
  source_security_group_id = module.ecs.backend_service_sg_id
  description              = "Backend ECS service to RDS"
}

resource "aws_security_group_rule" "backend_to_redis" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = module.db.redis_sg_id
  source_security_group_id = module.ecs.backend_service_sg_id
  description              = "Backend ECS service to ElastiCache Redis"
}
