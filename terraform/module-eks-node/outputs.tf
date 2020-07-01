output "node_iam_role_arn" {
  description = "EKS nodes IAM role ARN."
  value       = aws_iam_role.eks-node.arn
}

output "node_iam_instance_profile_name" {
  description = "EKS nodes IAM instance profile name."
  value       = aws_iam_instance_profile.eks-node.name
}