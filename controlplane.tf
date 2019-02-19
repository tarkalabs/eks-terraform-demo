resource "aws_iam_role" "eks-demo" {
  name = "eks-demo-role"

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
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-demo-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks-demo.name}"
}

resource "aws_iam_role_policy_attachment" "eks-demo-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks-demo.name}"
}

resource "aws_eks_cluster" "eks-demo" {
  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.eks-demo.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.eks-demo-controller.id}"]
    subnet_ids         = ["${aws_subnet.eks-demo.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-demo-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks-demo-AmazonEKSServicePolicy",
  ]
}
