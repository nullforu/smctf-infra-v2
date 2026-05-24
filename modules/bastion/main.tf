resource "aws_security_group" "bastion" {
  count       = var.create ? 1 : 0
  name        = "${var.name_prefix}-bastion"
  description = "SSM-only bastion host security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion"
  })
}

resource "aws_instance" "bastion" {
  count                       = var.create ? 1 : 0
  ami                         = local.effective_ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_ids[var.subnet_index]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion[0].id]
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion"
    Role = "bastion"
  })
}

locals {
  effective_ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.al2023[0].id
}

data "aws_ami" "al2023" {
  count       = var.create && var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
