provider "aws" {
  region = var.region
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
    bucket         = "terraform-be6f"
    key            = "smctf/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-be6f"
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

  s3_bucket_arn        = module.storage.s3_bucket_arn
  backend_image        = var.backend_image
  ecr_repository_names = var.ecr_repository_names

  enable_sandboxd                            = var.enable_sandboxd
  worker_instance_profile_policy_arns        = var.worker_instance_profile_policy_arns
  control_plane_instance_profile_policy_arns = var.control_plane_instance_profile_policy_arns

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

  backend_autoscaling_enabled              = var.backend_autoscaling_enabled
  backend_autoscaling_cpu_target           = var.backend_autoscaling_cpu_target
  backend_environment                      = var.backend_environment
  backend_log_retention_days               = var.backend_log_retention_days
  backend_health_check_interval_seconds    = var.backend_health_check_interval_seconds
  backend_health_check_timeout_seconds     = var.backend_health_check_timeout_seconds
  backend_health_check_healthy_threshold   = var.backend_health_check_healthy_threshold
  backend_health_check_unhealthy_threshold = var.backend_health_check_unhealthy_threshold
  ecs_task_execution_role_arn              = module.policy.ecs_task_execution_role_arn
  ecs_task_role_arn                        = module.policy.ecs_task_role_arn
}

module "sbxcluster" {
  source = "./modules/sbxcluster"

  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  enable_sandboxd = var.enable_sandboxd

  worker_node_count            = var.worker_node_count
  worker_node_instance_type    = var.worker_node_instance_type
  worker_node_ami_id           = var.worker_node_ami_id
  worker_node_key_name         = var.worker_node_key_name
  worker_node_root_volume_size = var.worker_node_root_volume_size

  control_plane_instance_type    = var.control_plane_instance_type
  control_plane_ami_id           = var.control_plane_ami_id
  control_plane_key_name         = var.control_plane_key_name
  control_plane_root_volume_size = var.control_plane_root_volume_size

  worker_public_port_range      = var.worker_public_port_range
  backend_to_control_plane_port = var.backend_to_control_plane_port
  control_plane_to_worker_port  = var.control_plane_to_worker_port

  backend_security_group_id = module.ecs.backend_service_sg_id
  bastion_security_group_id = module.bastion.security_group_id

  worker_instance_profile_name        = module.policy.worker_instance_profile_name
  control_plane_instance_profile_name = module.policy.control_plane_instance_profile_name
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

  vpc_id                = module.network.vpc_id
  protected_subnet_ids  = module.network.protected_subnet_ids
  backend_service_sg_id = module.ecs.backend_service_sg_id

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
