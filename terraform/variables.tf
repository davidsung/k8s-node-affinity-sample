variable "environment" {
  description = "Environment"
  default = "staging"
}

variable "aws_region" {
  default = "ap-southeast-1"
}

variable "aws_destination_profile" {
  description = "AWS Credentials for the Destination Profile"
}

// Destination VPC
variable "vpc_name" {
  description = "VPC Name"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
}

// EKS
variable "eks_name" {
  description = "EKS Cluster Name"
}

variable "eks_version" {
  description = "EKS Version"
  default = "1.16"
}

variable "eks_node_group_name" {
  description = "Managed Node Group Name"
  default = "managed-node-group"
}

variable "eks_node_group_desired_size" {
  description = "Managed Node Group Desired Size"
}

variable "eks_node_group_max_size" {
  description = "Managed Node Group Max Size"
}

variable "eks_node_group_min_size" {
  description = "Managed Node Group Min Size"
}
