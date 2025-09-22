# infra/variables.tf
variable "region" {
  description = "AWS region"
  type        = string
}

variable "default_vpc_id" {
  description = "Default VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for worker nodes (if self-managed)"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "SSH Key name for worker nodes"
  type        = string
  default     = ""
}
