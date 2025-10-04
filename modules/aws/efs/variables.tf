# ==========================
# Core Project Configuration
# ==========================

variable "project_name" {
  description = "The name of the project. Used consistently for naming, tagging, and organizational purposes across resources."
  type        = string
}

variable "name" {
  description = "The name of the project. Used consistently for naming, tagging, and organizational purposes across resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g., dev, staging, prod). Used for environment-specific tagging and naming."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EFS is deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnets to create mount targets in"
  type        = list(string)
}

variable "access_points" {
  type        = map(string)
}