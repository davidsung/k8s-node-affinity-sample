// Please specify the Destination AWS Profile (where the EKS stands up)
aws_destination_profile = "<AWS_PROFILE_NAME>"

environment = "staging"
aws_region = "ap-northeast-1"

# Destination VPC
vpc_name = "eks-vpc"
vpc_cidr = "10.0.0.0/16"

# EKS
eks_name = "octagon-eks"
eks_node_group_name = "octagon_managed_node_group"
eks_node_group_desired_size = 3
eks_node_group_min_size = 3
eks_node_group_max_size = 6