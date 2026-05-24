locals {
  control_plane_ingress_source_sg_ids = compact([
    var.backend_security_group_id,
    var.bastion_security_group_id
  ])
}

resource "aws_security_group" "control_plane" {
  count       = var.enable_sandboxd ? 1 : 0
  name        = "${var.name_prefix}-control-plane"
  description = "sandboxd-o control plane security group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = toset(local.control_plane_ingress_source_sg_ids)
    content {
      from_port       = var.backend_to_control_plane_port
      to_port         = var.backend_to_control_plane_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-control-plane" })
}

resource "aws_security_group" "worker" {
  count       = var.enable_sandboxd ? 1 : 0
  name        = "${var.name_prefix}-worker"
  description = "sandboxd-o worker nodes security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.worker_public_port_range.from
    to_port     = var.worker_public_port_range.to
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = var.control_plane_to_worker_port
    to_port         = var.control_plane_to_worker_port
    protocol        = "tcp"
    security_groups = [aws_security_group.control_plane[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-worker" })
}

resource "aws_instance" "control_plane" {
  count                       = var.enable_sandboxd ? 1 : 0
  ami                         = var.control_plane_ami_id
  instance_type               = var.control_plane_instance_type
  subnet_id                   = var.private_subnet_ids[0]
  key_name                    = var.control_plane_key_name
  vpc_security_group_ids      = [aws_security_group.control_plane[0].id]
  iam_instance_profile        = var.control_plane_instance_profile_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = var.control_plane_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-control-plane"
    Role = "control-plane"
  })
}

resource "aws_instance" "worker" {
  count                       = var.enable_sandboxd ? var.worker_node_count : 0
  ami                         = var.worker_node_ami_id
  instance_type               = var.worker_node_instance_type
  subnet_id                   = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  key_name                    = var.worker_node_key_name
  vpc_security_group_ids      = [aws_security_group.worker[0].id]
  iam_instance_profile        = var.worker_instance_profile_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.worker_node_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-worker-${count.index + 1}"
    Role = "worker-node"
  })
}
