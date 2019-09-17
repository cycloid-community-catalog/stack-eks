output "vpc_id" {
  description = "EKS Cluster dedicated VPC ID."
  value       = module.aws-vpc.vpc_id
}

output "private_subnets" {
  description = "EKS Cluster dedicated VPC private subnets."
  value       = module.aws-vpc.private_subnets
}

output "public_subnets" {
  description = "EKS Cluster dedicated VPC public subnets."
  value       = module.aws-vpc.public_subnets
}

output "private_zone_id" {
  description = "EKS Cluster dedicated VPC private zone ID."
  value       = aws_route53_zone.vpc_private.zone_id
}

output "bastion_sg_allow" {
  description = "EKS Cluster dedicated VPC bastion Security Group to allow SSH access to EC2 instances."
  value       = element(aws_security_group.allow_bastion.*.id, 0)
}