locals {
  backend_image_path       = join("/", slice(split("/", var.backend_image), 1, length(split("/", var.backend_image))))
  backend_image_repository = split("@", split(":", local.backend_image_path)[0])[0]
  wargame_ecr_repositories = [
    for repo_name in var.ecr_repository_names : repo_name
    if startswith(repo_name, "wargame_")
  ]
  worker_allowed_ecr_repositories = distinct(concat(
    local.wargame_ecr_repositories,
    [local.backend_image_repository]
  ))
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name_prefix}-ecs-task-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.name_prefix}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "ecs_task_s3" {
  name = "${var.name_prefix}-ecs-task-s3"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3BucketListAccess"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [var.s3_bucket_arn]
      },
      {
        Sid    = "S3ObjectReadWriteAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = ["${var.s3_bucket_arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role" "worker" {
  count = var.enable_sandboxd ? 1 : 0
  name  = "${var.name_prefix}-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "worker" {
  for_each = var.enable_sandboxd ? setsubtract(
    toset(var.worker_instance_profile_policy_arns),
    toset(["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])
  ) : toset([])

  role       = aws_iam_role.worker[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "worker_ssm_core" {
  count = var.enable_sandboxd ? 1 : 0

  role       = aws_iam_role.worker[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "worker_ecr_pull_allowlist" {
  count = var.enable_sandboxd && length(local.worker_allowed_ecr_repositories) > 0 ? 1 : 0
  name  = "${var.name_prefix}-worker-ecr-pull-allowlist"
  role  = aws_iam_role.worker[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "AllowlistedRepositoryPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = [
          for repo_name in local.worker_allowed_ecr_repositories :
          "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${repo_name}"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "worker" {
  count = var.enable_sandboxd ? 1 : 0
  name  = "${var.name_prefix}-worker-profile"
  role  = aws_iam_role.worker[0].name
}

resource "aws_iam_role" "control_plane" {
  count = var.enable_sandboxd ? 1 : 0
  name  = "${var.name_prefix}-control-plane-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "control_plane" {
  for_each = var.enable_sandboxd ? setsubtract(
    toset(var.control_plane_instance_profile_policy_arns),
    toset(["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])
  ) : toset([])

  role       = aws_iam_role.control_plane[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "control_plane_ssm_core" {
  count = var.enable_sandboxd ? 1 : 0

  role       = aws_iam_role.control_plane[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "control_plane" {
  count = var.enable_sandboxd ? 1 : 0
  name  = "${var.name_prefix}-control-plane-profile"
  role  = aws_iam_role.control_plane[0].name
}

resource "aws_iam_role" "bastion" {
  count = var.enable_bastion ? 1 : 0
  name  = "${var.name_prefix}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "bastion" {
  for_each = var.enable_bastion ? toset(var.bastion_instance_profile_policy_arns) : toset([])

  role       = aws_iam_role.bastion[0].name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "bastion" {
  count = var.enable_bastion ? 1 : 0
  name  = "${var.name_prefix}-bastion-profile"
  role  = aws_iam_role.bastion[0].name
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
