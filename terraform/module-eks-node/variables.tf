#
# General
#

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "aws_zones" {
  description = "To use specific AWS Availability Zones."
  default     = []
}

locals {
  aws_availability_zones = length(var.aws_zones) > 0 ? var.aws_zones : data.aws_availability_zones.available.names
}

variable "project" {
  description = "Cycloid project name."
}

variable "env" {
  description = "Cycloid environment name."
}

variable "customer" {
  description = "Cycloid customer name."
}

variable "keypair_name" {
  description = "AWS KeyPair name to use on EC2 instances."
  default     = "cycloid"
}

variable "extra_tags" {
  description = "Extra tags to add to all resources."
  default     = {}
}

locals {
  standard_tags = {
    "cycloid.io" = "true"
    env          = var.env
    project      = var.project
    client       = var.customer
  }
  merged_tags = merge(local.standard_tags, var.extra_tags)
}

#
# Networking
#

variable "vpc_id" {
  description = "VPC ID used to create the EKS Cluster."
}

variable "private_subnets_ids" {
  description = "VPC private subnets IDs to use to create the EKS nodes."
  type        = list(string)
}

variable "bastion_sg_allow" {
  description = "Bastion Security Group ID to allow SSH access on EKS nodes."
  default     = ""
}

variable "metrics_sg_allow" {
  description = "Metrics Security Group ID to allow prometheus scraping on EKS nodes."
  default     = ""
}

#
# Control plane
#

variable "cluster_name" {
  description = "EKS Cluster given name."
}

variable "cluster_version" {
  description = "EKS Cluster version for EKS nodes AMI"
}

variable "control_plane_sg_id" {
  description = "EKS Cluster Security Group ID."
}

variable "control_plane_endpoint" {
  description = "EKS Cluster endpoint."
}

variable "control_plane_ca" {
  description = "EKS Cluster certificate authority."
}

#
# Nodes
#

variable "node_iam_instance_profile_name" {
  description = "EKS nodes IAM instance profile name."
}

variable "node_group_name" {
  description = "EKS nodes group given name."
  default     = "standard"
}

variable "node_type" {
  description = "EKS nodes instance type."
  default     = "c3.xlarge"
}

variable "node_count" {
  description = "EKS nodes desired count."
  default     = 1
}

variable "node_asg_min_size" {
  description = "EKS nodes Auto Scaling Group minimum size."
  default     = 1
}

variable "node_asg_max_size" {
  description = "EKS nodes Auto Scaling Group maximum size."
  default     = 2
}

variable "node_update_min_in_service" {
  description = "Minimum EKS nodes in service during Auto Scaling Group rolling update."
  default     = 1
}

variable "node_associate_public_ip_address" {
  description = "Should be true if EIP address should be associated to EKS nodes."
  default     = false
}

variable "node_disk_type" {
  description = "EKS nodes root disk type."
  default     = "gp2"
}

variable "node_disk_size" {
  description = "EKS nodes root disk size."
  default     = "60"
}

variable "node_ebs_optimized" {
  description = "Should be true if the instance type is using EBS optimized volumes."
  default     = false
}
