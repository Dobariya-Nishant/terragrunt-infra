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

variable "hostedzone_id" {
  description = "hostedzone id to register alb with domain name"
  type        = string
}

# =========================
# ⚖️ Load Balancer Settings
# =========================

variable "domain_name" {
  description = "domain name"
  type        = string
}