output "name" {
  value = aws_ecs_cluster.this.name
}

output "id" {
  value = aws_ecs_cluster.this.id
}

output "asg" {
  description = "ASG details by name"
  value = {
    for k, asg in aws_autoscaling_group.this :
    k => {
      name         = asg.name
      arn          = asg.arn
    }
  }
}

