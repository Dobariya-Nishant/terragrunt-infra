# ==================
# 🌳 EFS File System
# ==================
resource "aws_efs_file_system" "this" {
  performance_mode = "generalPurpose"
  encrypted       = true

  lifecycle_policy {
    # automatically move files not accessed for 30 days to EFS IA
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.name}-efs-${var.environment}"
  }
}

# =================================
# 🖇️ Mount Targets (one per subnet)
# =================================
resource "aws_efs_mount_target" "this" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}

# =========================
# 🔐 Security Group for EFS
# =========================
resource "aws_security_group" "efs_sg" {
  name   = "${var.name}-efs-sg-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # adjust to your VPC/ALB SG in prod
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-efs-sg-${var.environment}"
  }
}

# =========================
# 🔐 Security Group for EFS
# =========================
resource "aws_efs_access_point" "this" {
  for_each = var.access_points
  file_system_id = aws_efs_file_system.this.id # your EFS id

  root_directory {
    path = each.value
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0770"
    }
  }

  tags = {
    Name = "${var.name}-ap-${var.environment}"
  }
}

