resource "aws_route53_zone" "vpc_private" {
  name = "${var.project}.eks.${var.env}"

  vpc {
    vpc_id = module.aws-vpc.vpc_id
  }

  tags = merge(local.merged_tags, {
    Name = "${var.project}.eks.${var.env}"
  })

  lifecycle {
    ignore_changes = ["vpc"]
  }
}

resource "aws_route53_zone_association" "vpc_private_external" {
  for_each = var.external_vpc_to_peer

  count = each.value.associate_to_dedicated_vpc_private_zone ? 1 : 0

  zone_id = aws_route53_zone.vpc_private.zone_id
  vpc_id  = each.value.id
}
