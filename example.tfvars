project     = "smctf"
environment = "dev"
region      = "ap-northeast-2"
azs         = ["ap-northeast-2a", "ap-northeast-2c"]

common_tags = {}

vpc_cidr               = "10.0.0.0/16"
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.11.0/24", "10.0.21.0/24"]
protected_subnet_cidrs = ["10.0.111.0/24", "10.0.121.0/24"]

nat_gateway_mode = "single"

enable_ssm_vpc_endpoints = true
enable_s3_vpc_endpoint   = true

acm_certificate_arn = "arn:aws:acm:ap-northeast-2:123456789012:certificate/replace-me"
alb_ingress_cidrs   = ["0.0.0.0/0"]

backend_image  = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/backend:latest"
backend_cpu    = 2048
backend_memory = 4096

backend_desired_count                    = 3
backend_autoscaling_enabled              = false
backend_min_count                        = 3
backend_max_count                        = 12
backend_autoscaling_cpu_target           = 70
backend_health_check_interval_seconds    = 20
backend_health_check_timeout_seconds     = 5
backend_health_check_healthy_threshold   = 2
backend_health_check_unhealthy_threshold = 2

# Invite bot (Discord). Deployed as a single ECS task (no sharding); see
# modules/ecs/invite_bot.tf. When invite_bot_enabled = true, the backend's
# DISCORD_BOT_BASE_URL is auto-set to the invite-bot Cloud Map DNS name.
invite_bot_enabled = false
invite_bot_image   = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/invite-bot:latest"
invite_bot_cpu     = 256
invite_bot_memory  = 512
invite_bot_environment = {
  DISCORD_BOT_TOKEN        = ""
  DISCORD_GUILD_ID         = ""
  DISCORD_VERIFIED_ROLE_ID = ""
  DISCORD_INTERNAL_SECRET  = "change-me"
}
backend_environment = {
  APP_ENV                   = "local"
  HTTP_ADDR                 = ":8080"
  SHUTDOWN_TIMEOUT          = "10s"
  AUTO_MIGRATE              = "true"
  BCRYPT_COST               = "12"
  COOKIE_DOMAIN             = ".swua.kr"
  DB_HOST                   = "10.10.0.1"
  DB_PORT                   = "25432"
  DB_USER                   = "app_user"
  DB_PASSWORD               = "app_password"
  DB_NAME                   = "app_db"
  DB_SSLMODE                = "disable"
  DB_MAX_OPEN_CONNS         = "25"
  DB_MAX_IDLE_CONNS         = "10"
  DB_CONN_MAX_LIFETIME      = "30m"
  REDIS_ADDR                = "10.10.0.1:26379"
  REDIS_PASSWORD            = ""
  REDIS_DB                  = "0"
  REDIS_POOL_SIZE           = "20"
  JWT_SECRET                = "change-me"
  JWT_ISSUER                = "smwargame"
  JWT_ACCESS_TTL            = "24h"
  JWT_REFRESH_TTL           = "168h"
  SUBMIT_WINDOW             = "1m"
  SUBMIT_MAX                = "10"
  TIMELINE_CACHE_TTL        = "60s"
  LEADERBOARD_CACHE_TTL     = "60s"
  APP_CONFIG_CACHE_TTL      = "2m"
  CORS_ALLOWED_ORIGINS      = "http://localhost:5173,https://ctf.example.com,https://ctf.swua.kr"
  LOG_DIR                   = "logs"
  LOG_FILE_PREFIX           = "app"
  LOG_MAX_BODY_BYTES        = "1048576"
  BOOTSTRAP_ADMIN_TEAM      = "true"
  BOOTSTRAP_ADMIN_USER      = "true"
  BOOTSTRAP_ADMIN_USERNAME  = "admin"
  BOOTSTRAP_ADMIN_EMAIL     = "admin@smwargame.com"
  BOOTSTRAP_ADMIN_PASSWORD  = "admin123!"
  S3_ENABLED                = "true"
  S3_REGION                 = "ap-northeast-2"
  S3_BUCKET                 = "smctf-challenges-bucket"
  S3_ACCESS_KEY_ID          = ""
  S3_SECRET_ACCESS_KEY      = ""
  S3_ENDPOINT               = ""
  S3_FORCE_PATH_STYLE       = "false"
  S3_PRESIGN_TTL            = "15m"
  VMS_ENABLED               = "true"
  VMS_MAX_SCOPE             = "team"
  VMS_MAX_PER               = "2"
  VMS_ORCHESTRATOR_BASE_URL = "http://10.10.0.1:8082"
  VMS_ORCHESTRATOR_SECRET   = "change-me"
  VMS_ORCHESTRATOR_TIMEOUT  = "5s"
  VMS_CREATE_WINDOW         = "1m"
  VMS_CREATE_MAX            = "1"

  DISCORD_ENABLED          = "false"
  DISCORD_CLIENT_ID        = ""
  DISCORD_CLIENT_SECRET    = "change-me"
  DISCORD_REDIRECT_URI     = "https://api.example.com/api/discord/callback"
  DISCORD_OAUTH_SCOPES     = "identify guilds.join"
  DISCORD_STATE_TTL        = "5m"
  DISCORD_OAUTH_TIMEOUT    = "10s"
  DISCORD_SUCCESS_REDIRECT = "https://ctf.example.com/profile"
  DISCORD_INVITE_URL       = ""
  DISCORD_AUTO_JOIN        = "true"
  DISCORD_BOT_BASE_URL     = "http://10.10.0.1:8083"
  DISCORD_BOT_SECRET       = "change-me"
  DISCORD_BOT_TIMEOUT      = "5s"
}
backend_log_retention_days = 14

enable_bastion           = true
bastion_subnet_index     = 0
bastion_ami_id           = null
bastion_instance_type    = "t3.micro"
bastion_root_volume_size = 20
bastion_key_name         = null
bastion_instance_profile_policy_arns = [
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
]

rds_instance_class        = "db.t3.micro"
rds_allocated_storage_gb  = 20
rds_multi_az              = false
rds_engine_version        = null
rds_db_name               = "smctf"
rds_master_username       = "smctf_admin"
rds_master_password       = "REPLACE_ME"
rds_backup_retention_days = 7
rds_deletion_protection   = true

redis_node_type       = "cache.t3.micro"
redis_engine_version  = null
redis_multi_az        = false
redis_num_cache_nodes = 1

s3_challenge_bucket_name   = "smctf-challenges-bucket"
create_s3_challenge_bucket = false

# s3_cors_rules = [
#   {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
#     allowed_origins = ["https://ctf.example.com"]
#     expose_headers  = ["ETag"]
#     max_age_seconds = 3000
#   }
# ]

ecr_repository_names    = ["backend", "smctf-challenges"]
create_ecr_repositories = false
