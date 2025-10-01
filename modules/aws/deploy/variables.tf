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


# =========================
# ECS Cluster Configuration
# =========================

variable "ecs_cluster_name" {
  description = "Deployment environment identifier (e.g., dev, staging, prod). Used for environment-specific tagging and naming."
  type        = string
}

variable "ecs_cluster_id" {
  description = "Deployment environment identifier (e.g., dev, staging, prod). Used for environment-specific tagging and naming."
  type        = string
}


# ==========================
# ECS Services Configuration
# ==========================

variable "services" {
  description = "ECS services config as a map"
  type = map(object({
    name                   = string
    desired_count          = number
    subnet_ids             = list(string)
    capacity_provider_name = optional(string, null)
    enable_public_http     = optional(bool, false)
    enable_public_https    = optional(bool, false)
    load_balancer_config = optional(object({
      listener_arn = string
      blue_target_group_name = string
      green_target_group_name = string
      blue_target_group_arn = string
      green_target_group_arn = string
      container_port   = number
      sg_id            = string
    }))

    task = object({
      name          = string
      cpu           = string
      memory        = string
      image_uri     = string
      essential     = bool
      command       = optional(list(string))
      environment   = optional(list(object({ 
        name = string
        value = string 
      })), [])
      portMappings  = optional(list(object({
        containerPort = number
        hostPort      = optional(number)
        protocol      = optional(string)
      })), [])
      task_role_arn = optional(string)
    })
  }))
}
