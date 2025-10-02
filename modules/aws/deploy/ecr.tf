resource "aws_ecr_repository" "this" {
  for_each = var.services

  name = "${each.key}-ecr-${var.environment}"

  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${each.key}-ecr-${var.environment}"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images, delete the rest"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
          countUnit     = "images"
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
