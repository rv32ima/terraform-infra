resource "aws_security_group" "rds" {
  name = "${var.prefix}-rds-sg"
  vpc_id = aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "rds" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 5432
  to_port = 5432
  ip_protocol = "tcp"
}

resource "aws_db_subnet_group" "this" {
  name = "${var.prefix}-subnet-group"
  subnet_ids = [for _, v in aws_subnet.private: v.id]
}

resource "aws_db_instance" "this" {
  identifier_prefix = "${var.prefix}-db"
  allocated_storage = 20
  instance_class = "db.t3.micro"
  engine = "postgres"
  engine_version = "17.6"
  username = "step"
  password = "oN4zb92aJv2cfMeo"
  db_name = "step"
  db_subnet_group_name = aws_db_subnet_group.this.name
  multi_az = false
  skip_final_snapshot = true
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  vpc_security_group_ids = [aws_security_group.rds.id]
}