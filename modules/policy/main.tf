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
