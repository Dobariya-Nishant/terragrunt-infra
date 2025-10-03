# =============================
# 🧱 Core Project Configuration
# =============================

variable "project_name" {
  description = "Name of the overall project. Used for consistent naming and tagging across all resources."
  type        = string
}

variable "name" {
  description = "Base name used as an identifier for all resources (e.g., key name, launch template name, etc.)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod). Used for tagging and naming consistency."
  type        = string
}

# =============
# 🌐 Networking
# =============

variable "vpc_id" {
  description = "The VPC ID where resources like EC2, ALB, and security groups will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to launch the ALB and associated resources into. Typically across multiple AZs."
  type        = list(string)
}

# ======================
# 🌐 Hosted Zone for DNS
# ======================

variable "hostedzone_id" {
  description = "Route53 Hosted Zone ID for your domain"
  type        = string
}

variable "domain_name" {
  description = "Domain name for ALB (example.com)"
  type        = string
}

# =============
# Target Groups
# =============

variable "target_groups" {
  description = "Map of target group definitions for blue/green"
  type = map(object({
    name        = string # name suffix for TG
    port        = number # port to listen on
    protocol    = string # HTTP or HTTPS
    target_type = string # instance or ip
  }))
}

# =========
# Listeners
# =========

variable "listener" {
  description = "Listener settings for ALB"
  type = object({
    name             = string
    target_group_key = string # default target group key to forward HTTPS traffic
    rules = map(object({
      description      = string
      target_group_key = string
      patterns         = list(string)
    }))
  })
}