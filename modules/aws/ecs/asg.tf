# ===========================
# 📈 Auto Scaling Group (ASG)
# ===========================
resource "aws_autoscaling_group" "this" {
  for_each = var.asg

  name                      = "${each.key}-asg-${var.environment}"
  desired_capacity          = lookup(each.value, "desired_capacity", each.value.min_size)
  max_size                  = each.value.max_size
  min_size                  = each.value.min_size
  health_check_grace_period = 300
  health_check_type         = "EC2"
  placement_group           = aws_placement_group.this[each.key].id
  vpc_zone_identifier       = each.value.subnet_ids
  protect_from_scale_in     = true

  metrics_granularity = "1Minute"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.this[each.key].id
    version = aws_launch_template.this[each.key].latest_version
  }
}

# ==================
# 🧱 Placement Group
# ==================
resource "aws_placement_group" "this" {
  for_each = var.asg

  name     = "${each.key}-pg-${var.environment}"
  strategy = "spread"
}

# ================================
# 🚀 Launch Template (used by ASG)
# ================================
resource "aws_launch_template" "this" {
  for_each = var.asg

  name   = "${each.key}-lt-${var.environment}"
  instance_type = each.value.instance_type
  image_id      = data.aws_ami.al2023_ecs_kernel6plus.image_id
  key_name      = aws_key_pair.this[each.key].key_name

  user_data = base64encode(data.template_file.ecs_user_data.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.this[each.key].name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = each.value.ebs_size
      volume_type           = each.value.ebs_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.this[each.key].id]
  }

  tags = {
    Name = "${each.key}-lt-${var.environment}"
  }
}

# ========================
# 🔐 TLS Key Pair Creation
# ========================
resource "tls_private_key" "this" {
  for_each = var.asg

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  for_each   = var.asg

  key_name   = "${each.key}-key-${var.environment}"
  public_key = tls_private_key.this[each.key].public_key_openssh
}

resource "local_file" "this" {
  for_each        = var.asg

  filename        = "${path.root}/keys/${aws_key_pair.this[each.key].key_name}.pem"
  content         = tls_private_key.this[each.key].private_key_openssh
  file_permission = "0600"
}

# ===========================================================
# 🔍 Fetch public IP of current machine (used for SSH access)
# ===========================================================
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

# =================================
# 🔒 Security Group + Ingress Rules
# =================================
resource "aws_security_group" "this" {
  for_each = var.asg

  description = "${each.key} Security Group"
  name = "${each.key}-sg-${var.environment}"
  vpc_id      = var.vpc_id
  
  dynamic "ingress" {
    for_each = each.value.enable_ssh_from_current_ip ? [1] : []
    content {
      description       = "Allow SSH"
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      cidr_blocks       = [data.http.my_ip.response_body]
    }
  }

  dynamic "ingress" {
    for_each = each.value.enable_public_ssh ? [1] : []
    content {
      description       = "Allow SSH"
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${each.key}-sg-${var.environment}"
  }
}

# =================================
# 🛡️ IAM Role + Profile for ECS EC2
# =================================
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "ecs_ec2_role_policy" {
  name = "AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role" "this" {
  for_each           = var.asg

  name               = "${each.key}-ecs-instance-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags = {
    Name = "${each.key}-ecs-instance-role-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each  = var.asg

  role      = aws_iam_role.this[each.key].name
  policy_arn = data.aws_iam_policy.ecs_ec2_role_policy.arn
}

resource "aws_iam_instance_profile" "this" {
  for_each = var.asg

  name     = "${each.key}-ecs-instance-profile-${var.environment}"
  role     = aws_iam_role.this[each.key].name
  tags = {
    Name = "${each.key}-ecs-instance-profile-${var.environment}"
  }
}

# ==============================================
# 🧾 ECS Cluster Registration Script (User Data)
# ==============================================
data "template_file" "ecs_user_data" {
  template = file("${path.module}/scripts/ecs_cluster_registration.sh.tpl")
  vars = {
    ecs_cluster_name = aws_ecs_cluster.this.name
  }
}

# ==========================================
# 📦 Amazon Linux 2023 ECS Optimized AMIs
# ==========================================
data "aws_ami" "al2023_ecs_kernel6plus" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023*-kernel-6*-x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}
