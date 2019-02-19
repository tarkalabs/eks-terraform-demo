resource "aws_vpc" "eks-demo" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
      "Name", "eks-demo-cluster-vpc",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "eks-demo" {
  count             = 2
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.eks-demo.id}"

  tags = "${
    map(
      "Name", "eks-demo-cluster-subnet",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "eks-demo" {
  vpc_id = "${aws_vpc.eks-demo.id}"
}

resource "aws_route_table" "eks-demo" {
  vpc_id = "${aws_vpc.eks-demo.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks-demo.id}"
  }
}

resource "aws_route_table_association" "eks-demo" {
  count          = 2
  route_table_id = "${aws_route_table.eks-demo.id}"
  subnet_id      = "${aws_subnet.eks-demo.*.id[count.index]}"
}
