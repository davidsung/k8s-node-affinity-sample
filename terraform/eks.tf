resource "aws_eks_cluster" "octagon_eks" {
  name     = var.eks_name
  role_arn = aws_iam_role.eks_role.arn

  # Put Nodes on Private Subnets across all AZs
  vpc_config {
    subnet_ids = module.eks_vpc.private_subnets
  }

  encryption_config {
    provider {
        key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]  
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.octagon-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.octagon-AmazonEKSServicePolicy,
  ]
}

resource "aws_iam_role" "eks_role" {
  name = "eks-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# IAM Role for Service Account
resource "aws_iam_role_policy_attachment" "octagon-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "octagon-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "octagon-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "octagon-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "octagon-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = []
  url             = aws_eks_cluster.octagon_eks.identity.0.oidc.0.issuer
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "oidc_provider_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "oidc_provider" {
  assume_role_policy = data.aws_iam_policy_document.oidc_provider_assume_role_policy.json
  name               = "oidc_provider"
}

# KMS Encryption Key for EKS Cluster
resource "aws_kms_key" "eks" {
  description         = "EKS Cluster Secrets Encryption Key"
  enable_key_rotation = true
}

# Managed Node Group
resource "aws_eks_node_group" "octagon_managed_node_group" {
  cluster_name    = aws_eks_cluster.octagon_eks.name
  node_group_name = var.eks_node_group_name
  node_role_arn   = aws_iam_role.eks_role.arn
  subnet_ids      = module.eks_vpc.private_subnets

  scaling_config {
    desired_size = var.eks_node_group_desired_size
    max_size     = var.eks_node_group_max_size
    min_size     = var.eks_node_group_min_size
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.octagon-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.octagon-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.octagon-AmazonEC2ContainerRegistryReadOnly,
  ]
}
