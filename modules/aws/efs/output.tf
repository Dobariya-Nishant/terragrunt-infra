output "id" {
  value = aws_efs_file_system.this.id
}

output "name" {
  value = aws_efs_file_system.this.name
}

output "arn" {
  value = aws_efs_file_system.this.arn
}

output "access_points_ids" {
  value =  {
    for k, ap in aws_efs_access_point.this :
    k => {
      id  = ap.id
    }
  }
}