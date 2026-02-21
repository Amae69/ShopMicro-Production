variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "eu-west-2"
}

variable "instance_type_master" {
  description = "EC2 instance type for the Kubernetes master node"
  default     = "t3.small"
}

variable "instance_type_worker" {
  description = "EC2 instance type for the Kubernetes worker node"
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair to allow SSH access"
  type        = string
  default     = "ec2-key" # This is my actual key pair name
}

variable "environment" {
  description = "Environment name"
  default     = "shopmicro-capstone"
}
