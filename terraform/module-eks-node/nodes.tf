#
# Security Groups
#

resource "aws_security_group" "eks-node" {
  name        = "${var.project}-${var.env}-eks-node-${var.node_group_name}"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.eks.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.merged_tags, {
    Name                                        = "${var.project}-${var.env}-eks-node-${var.node_group_name}"
    role                                        = "eks-node"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/node-group/name"             = "${var.node_group_name}"
  })
}

resource "aws_security_group_rule" "eks-node-ingress-self" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks-node.id
  source_security_group_id = aws_security_group.eks-node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-ingress-cluster" {
  description              = "Allow nodes Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node.id
  source_security_group_id = var.control_plane_sg_id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = var.control_plane_sg_id
  source_security_group_id = aws_security_group.eks-node.id
  to_port                  = 443
  type                     = "ingress"
}

#
# Auto Scaling Group
#

locals {
  node_tags =  concat([
            for tag in keys(local.merged_tags):
               { "Key" = tag, "Value" = local.merged_tags[tag], "PropagateAtLaunch" = "true" }
          ],
          [
               { "Key" = "Name", "Value" = "${var.project}-${var.env}-eks-node-${var.node_group_name}", "PropagateAtLaunch" = "true" },
               { "Key" = "role", "Value" = "eks-node", "PropagateAtLaunch" = "true" }
               { "Key" = "kubernetes.io/cluster/${var.cluster_name}", "Value" = "owned", "PropagateAtLaunch" = "true" }
               { "Key" = "kubernetes.io/cluster/name", "Value" = "${var.node_group_name}", "PropagateAtLaunch" = "true" }
          ])
}

# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
data "template_file" "user-data-eks-node" {
  template = file("${path.module}/templates/userdata.sh.tpl")

  vars = {
    signal_stack_name  = "${var.project}-${var.env}-eks-node-${var.node_group_name}"
    signal_resource_id = "EKSNodes${var.env}"

    apiserver_endpoint = var.control_plane_endpoint
    b64_cluster_ca     = var.control_plane_ca
    cluster_name       = var.cluster_name
  }
}

resource "aws_launch_template" "eks-node" {
  name_prefix   = "${var.project}-${var.env}-eks-node-${var.node_group_name}-version_"
  image_id      = data.aws_ami.eks-node.id
  instance_type = var.node_type
  user_data     = base64encode(data.template_file.user-data-eks-node.rendered)
  key_name      = var.keypair_name

  /*
  instance_market_options {
    market_type = "spot"

    spot_options {
      spot_instance_type = "one-time"
      max_price          = "${var.node_spot_price}"
    }
  }
  */

  network_interfaces {
    associate_public_ip_address = var.node_associate_public_ip_address
    delete_on_termination       = true

    security_groups = compact(
      [
        aws_security_group.eks-node.id,
        var.bastion_sg_allow,
        var.metrics_sg_allow,
      ],
    )
  }

  lifecycle {
    create_before_destroy = true
  }

  iam_instance_profile {
    name = var.node_instance_profile_name
  }

  tags = merge(local.merged_tags, {
    Name                                        = "${var.project}-${var.env}-eks-node-${var.node_group_name}-template"
    role                                        = "eks-node-template"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/node-group/name"             = "${var.node_group_name}"
  })

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.merged_tags, {
      Name                                        = "${var.project}-${var.env}-eks-node-${var.node_group_name}"
      role                                        = "eks-node"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "kubernetes.io/node-group/name"             = "${var.node_group_name}"
    })
  }
  tag_specifications {
    resource_type = "volume"

    tags = merge(local.merged_tags, {
      Name                                        = "${var.project}-${var.env}-eks-node-${var.node_group_name}"
      role                                        = "eks-node"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "kubernetes.io/node-group/name"             = "${var.node_group_name}"
    })
  }

  # block_device_mappings {
  #   device_name = "xvda"

  #   ebs {
  #     volume_size           = var.node_disk_size
  #     volume_type           = var.node_disk_type
  #     delete_on_termination = true
  #   }
  # }
  # ebs_optimized = var.node_ebs_optimized
}

resource "aws_cloudformation_stack" "eks-node" {
  name = "${var.project}-${var.env}-eks-node-${var.node_group_name}"

  # "HealthCheckType": "ELB",
  # "TargetGroupARNs": ["${aws_alb_target_group.front-80.arn}"],
  # "HealthCheckGracePeriod": 600,
  template_body = <<EOF
{
  "Resources": {
    "EKSNodes${var.env}": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "AvailabilityZones": ${jsonencode(local.aws_availability_zones)},
        "VPCZoneIdentifier": ${jsonencode(var.private_subnets_ids)},
        "LaunchTemplate": {
            "LaunchTemplateId": "${aws_launch_template.eks-node.id}",
            "Version" : "${aws_launch_template.eks-node.latest_version}"
        },
        "DesiredCapacity": "${var.node_count}",
        "MinSize": "${var.node_asg_min_size}",
        "MaxSize": "${var.node_asg_max_size}",
        "TerminationPolicies": ["OldestLaunchConfiguration", "NewestInstance"],
        "Tags" : ${jsonencode(local.node_tags)}
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "${var.node_update_min_in_service}",
          "MinSuccessfulInstancesPercent": "50",
          "SuspendProcesses": ["ScheduledActions"],
          "MaxBatchSize": "1",
          "PauseTime": "PT8M",
          "WaitOnResourceSignals": "true"
        }
      }
    }
  },
  "Outputs": {
    "AsgName": {
      "Description": "The name of the auto scaling group",
       "Value": {"Ref": "EKSNodes${var.env}"}
    }
  }
}
EOF

}
