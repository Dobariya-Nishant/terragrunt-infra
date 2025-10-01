# =============================
# 📦 Core VPC Module Input Vars
# =============================

variable "project_name" {
  description = "The name of the project this infrastructure is associated with. Used for naming and tagging resources."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod). Helps differentiate resources across environments."
  type        = string
}

variable "name" {
  description = "The name assigned to the Virtual Private Cloud (VPC). Used in resource naming and tagging."
  type        = string
}

# ========================
# 🌐 Networking Parameters
# ========================

variable "cidr_block" {
  description = "The CIDR block for the VPC (e.g., 10.0.0.0/16). Defines the IP address range for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "A list of CIDR blocks for public subnets. These subnets are intended for resources that must be accessible from the internet."
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of CIDR blocks for private subnets. These subnets are for internal resources that do not require direct access from the internet."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Boolean flag to enable or disable the creation of a NAT Gateway. Requires at least one public subnet if set to true."
  type        = bool
  default     = false

  validation {
    condition     = !(var.enable_nat_gateway == true && length(var.public_subnets) == 0)
    error_message = "At least one public subnet is required when NAT Gateway is enabled."
  }
}

variable "availability_zones" {
  description = "A list of availability zones to distribute the subnets across. Enhances availability and fault tolerance."
  type        = list(string)
}
