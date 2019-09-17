# VPC
output "vpc_id" {
  description = "EKS Cluster VPC ID."
  value       = module.vpc.outputs.vpc_id
}

output "public_subnets" {
  description = "EKS Cluster VPC public subnets."
  value       = module.vpc.outputs.public_subnets
}

output "private_subnets" {
  description = "EKS Cluster VPC private subnets."
  value       = module.vpc.outputs.private_subnets
}

output "private_zone_id" {
  description = "EKS Cluster dedicated VPC private zone ID."
  value       = module.vpc.outputs.private_zone_id
}

output "bastion_sg_allow" {
  description = "EKS Cluster dedicated VPC bastion Security Group to allow SSH access to EC2 instances."
  value       = module.vpc.outputs.bastion_sg_allow
}

# EKS Cluster
output "eks_control_plane_sg_id" {
  description = "EKS Cluster Security Group ID."
  value       = module.vpc.outputs.eks_control_plane_sg_id
}

output "eks_control_plane_endpoint" {
  description = "EKS Cluster endpoint."
  value       = module.vpc.outputs.eks_control_plane_endpoint
}

output "eks_control_plane_ca" {
  description = "EKS Cluster certificate authority."
  value       = module.vpc.outputs.eks_control_plane_ca
}

output "eks_node_iam_role_arn" {
  description = "EKS nodes IAM role ARN."
  value       = module.vpc.outputs.eks_node_iam_role_arn
}

output "eks_node_iam_instance_profile_name" {
  description = "EKS nodes IAM instance profile name." 
  value       = module.vpc.outputs.eks_node_iam_instance_profile_name
}

output "kubeconfig" {
  description = "Kubernetes config to connect to the EKS cluster."
  value       = module.eks.outputs.kubeconfig
}
