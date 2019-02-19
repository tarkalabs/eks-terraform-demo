
resource "aws_iam_role" "eks-demo-node" {
  name = "eks-demo-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
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

resource "aws_iam_role_policy_attachment" "eks-demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks-demo-node.name}"
}

resource "aws_iam_role_policy_attachment" "eks-demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks-demo-node.name}"
}

resource "aws_iam_role_policy_attachment" "eks-demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks-demo-node.name}"
}

resource "aws_iam_instance_profile" "eks-demo-node" {
  name = "eks-demo-node"
  role = "${aws_iam_role.eks-demo-node.name}"
}


data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.eks-demo.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks-demo.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks-demo.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "eks-demo" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks-demo-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "eks-demo"
  security_groups             = ["${aws_security_group.eks-demo-node.id}"]
  user_data_base64            = "${base64encode(local.demo-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks-demo" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.eks-demo.id}"
  max_size             = 2
  min_size             = 1
  name                 = "eks-demo"
  vpc_zone_identifier  = ["${aws_subnet.eks-demo.*.id}"]

  tag {
    key                 = "Name"
    value               = "eks-demo"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
