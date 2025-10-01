# ==========================
# Core Project Configuration
# ==========================

variable "project_name" {
  description = "The name of the project. Used consistently for naming, tagging, and organizational purposes across resources."
  type        = string
}

variable "name" {
  description = "Base name identifier applied to all resources (e.g., cluster name, IAM roles, etc.) for consistent resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g., dev, staging, prod). Used for environment-specific tagging and naming."
  type        = string
}

# ==========
# Networking
# ==========

variable "vpc_id" {
  description = "The VPC ID where resources like EC2, security groups, etc. will be deployed."
  type        = string
}

# =========================
# Auto Scaling Groups (ASG)
# =========================

variable "asg" {
  description = "Map of ASGs with their configs (optional)"
  type = map(object({
    instance_type              = string
    min_size                   = number
    max_size                   = number
    subnet_ids                 = list(string)
    ebs_size                   = optional(number, 30)
    ebs_type                   = optional(string, "gp2")
    enable_ssh_from_current_ip = optional(bool, false)
    enable_public_ssh          = optional(bool, false)
  }))
  default = {}
}
