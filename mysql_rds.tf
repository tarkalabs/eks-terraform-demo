resource "aws_db_subnet_group" "db_subnetgroup" {
  description = "mysql db subnet group"
  name        = "mysql_subnet_group"
  subnet_ids  = ["${aws_subnet.eks-demo.*.id}"]

  tags {
    Name = "mysql_db_subnet_group"
  }
}

resource "aws_security_group" "rds_security_group" {
  name        = "eks-demo-rds-mysql"
  description = "Security group for all rds nodes in cluster"
  vpc_id      = "${aws_vpc.eks-demo.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-demo-rds-mysql"
  }
}

resource "aws_security_group_rule" "rds_security_group_incoming_node" {
  description              = "allow all nodes/pods to communicate"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.rds_security_group.id}"
  source_security_group_id = "${aws_security_group.eks-demo-node.id}"
  type                     = "ingress"
}

resource "aws_security_group_rule" "rds_security_group_incoming_cp" {
  description              = "allow control plane to communicate"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.rds_security_group.id}"
  source_security_group_id = "${aws_security_group.eks-demo-controller.id}"
  type                     = "ingress"
}

resource "aws_db_instance" "mysql_db" {
  identifier             = "eks-demo-mysql-instance"
  allocated_storage      = 10
  engine                 = "mariadb"
  engine_version         = "10.3.8"
  instance_class         = "db.t2.micro"
  name                   = "tarkalabsdemo"
  username               = "dbuser"
  password               = "${var.rds-db-password}"
  vpc_security_group_ids = ["${aws_security_group.rds_security_group.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.db_subnetgroup.id}"
  skip_final_snapshot    = true
}
