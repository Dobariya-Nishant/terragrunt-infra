output "id" {
  description = "Application Load Balancer ID."
  value       = aws_lb.this.id
}

output "sg_id" {
  description = "Security group ID attached to the ALB."
  value       = aws_security_group.this.id
}

output "https_listener_arn" {
  description = "ARN of the ALB HTTPS listener."
  value       = aws_lb_listener.https.arn
}

output "blue_client_tg_arn" {
  description = "ARN of the blue (active) target group for client traffic."
  value       = aws_lb_target_group.blue_client.arn
}

output "blue_client_tg_name" {
  description = "ARN of the blue (active) target group for client traffic."
  value       = aws_lb_target_group.blue_client.name
}

output "green_client_tg_arn" {
  description = "ARN of the green (test) target group for client traffic."
  value       = aws_lb_target_group.green_client.arn
}

output "green_client_tg_name" {
  description = "ARN of the blue (active) target group for client traffic."
  value       = aws_lb_target_group.green_client.name
}

output "blue_api_tg_arn" {
  description = "ARN of the blue (active) target group for API traffic."
  value       = aws_lb_target_group.blue_api.arn
}

output "blue_api_tg_name" {
  description = "ARN of the blue (active) target group for client traffic."
  value       = aws_lb_target_group.blue_api.name
}

output "green_api_tg_arn" {
  description = "ARN of the green (test) target group for API traffic."
  value       = aws_lb_target_group.green_api.arn
}

output "green_api_tg_name" {
  description = "ARN of the blue (active) target group for client traffic."
  value       = aws_lb_target_group.green_api.name
}