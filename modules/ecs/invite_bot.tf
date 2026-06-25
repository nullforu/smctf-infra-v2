locals {
  invite_bot_count          = var.invite_bot_enabled ? 1 : 0
  invite_bot_container_name = "invite-bot"

  backend_environment_effective = merge(
    var.backend_environment,
    var.invite_bot_enabled ? {
      DISCORD_BOT_BASE_URL = "http://${aws_service_discovery_service.invite_bot[0].name}.${aws_service_discovery_private_dns_namespace.internal[0].name}:8083"
    } : {}
  )
}

resource "aws_service_discovery_private_dns_namespace" "internal" {
  count       = local.invite_bot_count
  name        = "${var.name_prefix}.internal"
  description = "Internal service discovery namespace for ${var.name_prefix}"
  vpc         = var.vpc_id
  tags        = var.tags
}

resource "aws_service_discovery_service" "invite_bot" {
  count = local.invite_bot_count
  name  = "invite-bot"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal[0].id

    dns_records {
      type = "A"
      ttl  = 10
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  tags = var.tags
}

resource "aws_security_group" "invite_bot" {
  count       = local.invite_bot_count
  name        = "${var.name_prefix}-invite-bot"
  description = "Invite bot ECS service security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Internal API from backend"
    from_port       = 8083
    to_port         = 8083
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-invite-bot" })
}

resource "aws_cloudwatch_log_group" "invite_bot" {
  count             = local.invite_bot_count
  name              = "/aws/ecs/${var.name_prefix}/invite-bot"
  retention_in_days = var.invite_bot_log_retention_days
  tags              = var.tags
}

resource "aws_ecs_task_definition" "invite_bot" {
  count                    = local.invite_bot_count
  family                   = "${var.name_prefix}-invite-bot"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.invite_bot_cpu)
  memory                   = tostring(var.invite_bot_memory)
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = local.invite_bot_container_name
      image     = var.invite_bot_image
      essential = true
      portMappings = [{
        containerPort = 8083
        hostPort      = 8083
        protocol      = "tcp"
      }]
      environment = [
        for k, v in merge({ HTTP_ADDR = ":8083" }, var.invite_bot_environment) : {
          name  = k
          value = v
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.invite_bot[0].name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "invite-bot"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "invite_bot" {
  count           = local.invite_bot_count
  name            = "invite-bot"
  cluster         = aws_ecs_cluster.backend.id
  task_definition = aws_ecs_task_definition.invite_bot[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.invite_bot[0].id]
    subnets          = var.private_subnet_ids
  }

  service_registries {
    registry_arn = aws_service_discovery_service.invite_bot[0].arn
  }

  tags = var.tags
}
