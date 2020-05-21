output "endpoint" {
  value = aws_eks_cluster.octagon_eks.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.octagon_eks.id
}