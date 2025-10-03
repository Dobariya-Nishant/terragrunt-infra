output "name" {
  value = aws_ecs_cluster.this.name
}

output "id" {
  value = aws_ecs_cluster.this.id
}

output "asg_cp" {
  description = "ASG details by name"
  value = {
    for k, cp in aws_ecs_capacity_provider.this :
    k => {
      name = cp.name
      arn  = cp.arn
    }
  }
}

