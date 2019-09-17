#
# Dedicated VPC
#

module "aws-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v1.0"

  name = "${var.project}-eks-${var.env}"
  azs  = local.aws_availability_zones
  cidr = var.vpc_cidr

  enable_nat_gateway  = true
  single_nat_gateway  = true

  private_subnets     = var.private_subnets
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
  public_subnets      = var.public_subnets
  public_subnet_tags  = {
    "kubernetes.io/role/elb" = "1"    
  }

  enable_dns_hostnames     = true
  enable_dhcp_options      = true
  dhcp_options_domain_name = "${var.project}.eks.${var.env}"

  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint

  tags = merge(local.merged_tags, {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

#
# Peering with external VPCs
#

resource "aws_vpc_peering_connection" "external_dedicated" {
  for_each = var.external_vpc_to_peer

  peer_vpc_id = each.value.id
  vpc_id      = module.aws-vpc.vpc_id
  auto_accept = true

  tags = merge(local.merged_tags, {
    Name       = "VPC Peering between `${each.value.name}` external VPC and the dedicated `${var.project}-${var.env}-eks` VPC"
  })
}

resource "aws_route" "external_dedicated_public" {
  for_each = var.external_vpc_to_peer

  count = length(each.value.public_route_table_ids)

  route_table_id            = element(each.value.public_route_table_ids, count.index)
  destination_cidr_block    = module.aws-vpc.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.external_dedicated.id
}

resource "aws_route" "external_dedicated_private" {
  for_each = var.external_vpc_to_peer

  count = length(each.value.private_route_table_ids)

  route_table_id            = element(each.value.private_route_table_ids, count.index)
  destination_cidr_block    = module.aws-vpc.cidr
  vpc_peering_connection_id = "${aws_vpc_peering_connection.external_dedicated.id}"
}

resource "aws_route" "dedicated_external_public" {
  for_each = var.external_vpc_to_peer

  count = length(module.aws-vpc.public_subnets) > 0 ? 1 : 0

  route_table_id            = element(module.aws-vpc.public_route_table_ids, count.index)
  destination_cidr_block    = each.value.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.external_dedicated.id
}

# Fix for value of count cannot be computed, generating the count as the same way as amazon vpc module do : https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/main.tf#L5
locals {
  vpc_nat_gateway_count    = var.single_nat_gateway ? 1 : (var.one_nat_gateway_per_az ? length(local.aws_availability_zones) : length(module.aws-vpc.private_subnets))
}

resource "aws_route" "dedicated_external_private" {
  for_each = var.external_vpc_to_peer

  count = length(module.aws-vpc.private_subnets) > 0 ? local.vpc_nat_gateway_count : 0

  route_table_id            = element(module.aws-vpc.private_route_table_ids, count.index)
  destination_cidr_block    = each.value.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.external_dedicated.id
}
