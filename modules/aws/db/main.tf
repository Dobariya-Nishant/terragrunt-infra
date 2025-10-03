

# DocumentDB Cluster
resource "aws_docdb_cluster" "this" {
  cluster_identifier     = "${var.name}-db-cluster-${var.environment}"
  engine                 = "docdb"
  master_username        = "poweruser"
  master_password        = "SuperSecret123!"
  db_subnet_group_name   = aws_docdb_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  skip_final_snapshot    = var.skip_final_snapshot # dev/test only

  tags = {
    Name = "${var.name}-db-cluster-${var.environment}"
  }
}

# Subnet Group
resource "aws_docdb_subnet_group" "this" {
  name       = "${var.name}-db-group-${var.environment}"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name}-db-group-${var.environment}"
  }
}

# Single Cluster Instance (low cost)
resource "aws_docdb_cluster_instance" "this" {
  count              = 1
  identifier         = "${var.name}-db-${var.environment}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = "db.t3.medium" # lowest-cost instance

  tags = {
    Name = "${var.name}-db-${var.environment}"
  }
}

# Security Group to allow your IP to connect on port 27017
resource "aws_security_group" "this" {
  name   = "${var.name}-db-sg-${var.environment}"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_ip != null ? [1] : []
    content {
      description = "Allow HTTPS"
      from_port   = 27017
      to_port     = 27017
      protocol    = "tcp"
      cidr_blocks = ["${var.allowed_ip}/32"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-db-sg-${var.environment}"
  }
}