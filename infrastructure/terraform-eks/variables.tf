variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "The name of the project, used for naming resources"
  type        = string
  default     = "shopmicro-production"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "shopmicro-eks"
}

variable "instance_type" {
  description = "Instance type for the EKS node group"
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 3
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"] # Matches default aws_region
}
