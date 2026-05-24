variable "project" {
  type        = string
  description = "Project name."
  default     = "smctf"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)."
  default     = "dev"
}

variable "region" {
  type        = string
  description = "AWS region."
  default     = "ap-northeast-2"
}

variable "azs" {
  type        = list(string)
  description = "AZs to use (must be 2 for this design)."
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "common_tags" {
  type        = map(string)
  description = "Extra tags applied to all resources."
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs."
  default     = ["10.0.11.0/24", "10.0.21.0/24"]
}

variable "protected_subnet_cidrs" {
  type        = list(string)
  description = "Protected subnet CIDRs for DB."
  default     = ["10.0.111.0/24", "10.0.121.0/24"]
}

variable "nat_gateway_mode" {
  type        = string
  description = "NAT gateway placement: single or per_az."
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be single or per_az."
  }
}

variable "enable_ssm_vpc_endpoints" {
  type        = bool
  description = "Create VPC interface endpoints for SSM/SSMMessages/EC2Messages."
  default     = true
}

variable "enable_s3_vpc_endpoint" {
  type        = bool
  description = "Create VPC gateway endpoint for S3."
  default     = true
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS listener on ALB."
}

variable "alb_ingress_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access ALB (80/443)."
  default     = ["0.0.0.0/0"]
}

variable "backend_image" {
  type        = string
  description = "ECS backend container image URI."
}

variable "backend_cpu" {
  type        = number
  description = "Fargate task CPU units."
  default     = 2048
}

variable "backend_memory" {
  type        = number
  description = "Fargate task memory (MiB)."
  default     = 4096
}

variable "backend_desired_count" {
  type        = number
  description = "Desired ECS task count for backend service."
  default     = 3
}

variable "backend_autoscaling_enabled" {
  type        = bool
  description = "Enable backend ECS service autoscaling."
  default     = false
}

variable "backend_min_count" {
  type        = number
  description = "Minimum task count when autoscaling is enabled."
  default     = 3
}

variable "backend_max_count" {
  type        = number
  description = "Maximum task count when autoscaling is enabled."
  default     = 12
}

variable "backend_autoscaling_cpu_target" {
  type        = number
  description = "Target CPU utilization percentage for backend autoscaling."
  default     = 70
}

variable "backend_environment" {
  type        = map(string)
  description = "Environment variables injected into backend container."
  default     = {}
}

variable "backend_log_retention_days" {
  type        = number
  description = "CloudWatch log retention days for backend ECS logs."
  default     = 14
}

variable "backend_health_check_interval_seconds" {
  type        = number
  description = "ALB target group health check interval in seconds."
  default     = 20
}

variable "backend_health_check_timeout_seconds" {
  type        = number
  description = "ALB target group health check timeout in seconds."
  default     = 5
}

variable "backend_health_check_healthy_threshold" {
  type        = number
  description = "Consecutive successful checks required to mark healthy."
  default     = 2
}

variable "backend_health_check_unhealthy_threshold" {
  type        = number
  description = "Consecutive failed checks required to mark unhealthy."
  default     = 2
}

variable "enable_sandboxd" {
  type        = bool
  description = "Whether to provision sandboxd-o control plane and worker nodes."
  default     = true
}

variable "worker_node_count" {
  type        = number
  description = "Number of sandboxd-o worker node EC2 instances."
  default     = 2
}

variable "worker_node_instance_type" {
  type        = string
  description = "EC2 instance type for sandboxd-o worker nodes."
  default     = "t3a.medium"
}

variable "worker_node_ami_id" {
  type        = string
  description = "AMI ID for sandboxd-o worker nodes."
}

variable "worker_node_key_name" {
  type        = string
  description = "Optional key pair name for worker nodes."
  default     = null
}

variable "worker_node_root_volume_size" {
  type        = number
  description = "Root volume size in GiB for worker nodes."
  default     = 40

  validation {
    condition     = var.worker_node_root_volume_size >= 32
    error_message = "worker_node_root_volume_size must be at least 32 GiB for the current AMI snapshot baseline."
  }
}

variable "control_plane_instance_type" {
  type        = string
  description = "EC2 instance type for sandboxd-o control plane."
  default     = "t3a.medium"
}

variable "control_plane_ami_id" {
  type        = string
  description = "AMI ID for sandboxd-o control plane node."
}

variable "control_plane_key_name" {
  type        = string
  description = "Optional key pair name for control plane node."
  default     = null
}

variable "control_plane_root_volume_size" {
  type        = number
  description = "Root volume size in GiB for control plane node."
  default     = 40

  validation {
    condition     = var.control_plane_root_volume_size >= 32
    error_message = "control_plane_root_volume_size must be at least 32 GiB for the current AMI snapshot baseline."
  }
}

variable "worker_public_port_range" {
  type = object({
    from = number
    to   = number
  })
  description = "Publicly exposed port range for worker nodes."
  default = {
    from = 10000
    to   = 32767
  }
}

variable "backend_to_control_plane_port" {
  type        = number
  description = "Control plane (sbxorch) port exposed to backend SG."
  default     = 8082
}

variable "control_plane_to_worker_port" {
  type        = number
  description = "Worker (sbxlet) API port exposed to control plane SG."
  default     = 8081
}

variable "worker_instance_profile_policy_arns" {
  type        = list(string)
  description = "IAM managed policy ARNs attached to worker node role."
  default = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}

variable "control_plane_instance_profile_policy_arns" {
  type        = list(string)
  description = "IAM managed policy ARNs attached to control plane role."
  default = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}

variable "enable_bastion" {
  type        = bool
  description = "Whether to provision an SSM Session Manager bastion host."
  default     = true
}

variable "bastion_subnet_index" {
  type        = number
  description = "Index of private subnet to place bastion in."
  default     = 0
}

variable "bastion_ami_id" {
  type        = string
  description = "Optional AMI ID for bastion. If null, latest Amazon Linux 2023 is used."
  default     = null
}

variable "bastion_instance_type" {
  type        = string
  description = "EC2 instance type for bastion host."
  default     = "t3.micro"
}

variable "bastion_root_volume_size" {
  type        = number
  description = "Root volume size in GiB for bastion host."
  default     = 20
}

variable "bastion_key_name" {
  type        = string
  description = "Optional key pair name for bastion host."
  default     = null
}

variable "bastion_instance_profile_policy_arns" {
  type        = list(string)
  description = "IAM managed policy ARNs attached to bastion host role."
  default = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}

variable "rds_instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t3.micro"
}

variable "rds_allocated_storage_gb" {
  type        = number
  description = "RDS allocated storage in GB."
  default     = 20
}

variable "rds_multi_az" {
  type        = bool
  description = "Enable RDS Multi-AZ."
  default     = false
}

variable "rds_engine_version" {
  type        = string
  description = "RDS PostgreSQL engine version (null to use AWS default)."
  default     = null
}

variable "rds_db_name" {
  type        = string
  description = "RDS database name."
  default     = "smctf"
}

variable "rds_master_username" {
  type        = string
  description = "RDS master username."
  default     = "smctf_admin"
}

variable "rds_master_password" {
  type        = string
  description = "RDS master password."
  sensitive   = true
}

variable "rds_backup_retention_days" {
  type        = number
  description = "RDS backup retention days."
  default     = 7
}

variable "rds_deletion_protection" {
  type        = bool
  description = "Enable RDS deletion protection."
  default     = true
}

variable "redis_node_type" {
  type        = string
  description = "ElastiCache Redis node type."
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  type        = string
  description = "ElastiCache Redis engine version (null to use AWS default)."
  default     = null
}

variable "redis_multi_az" {
  type        = bool
  description = "Enable Redis Multi-AZ / automatic failover."
  default     = false
}

variable "redis_num_cache_nodes" {
  type        = number
  description = "Number of cache nodes (1 for single-AZ, 2+ for multi-AZ)."
  default     = 1
}

variable "s3_challenge_bucket_name" {
  type        = string
  description = "S3 bucket name for challenge files."
  default     = "smctf-challenges-bucket"
}

variable "create_s3_challenge_bucket" {
  type        = bool
  description = "Whether to create the challenge files bucket."
  default     = true

  validation {
    condition     = var.create_s3_challenge_bucket || (var.s3_challenge_bucket_name != null && trimspace(var.s3_challenge_bucket_name) != "")
    error_message = "When create_s3_challenge_bucket is false, s3_challenge_bucket_name must be set."
  }
}

variable "s3_cors_rules" {
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  description = "CORS rules for challenge files bucket. Empty list disables CORS."
  default     = []
}

variable "ecr_repository_names" {
  type        = list(string)
  description = "ECR repository names to create."
  default     = ["backend", "smctf-challenges"]
}

variable "create_ecr_repositories" {
  type        = bool
  description = "Whether to create ECR repositories."
  default     = true
}
