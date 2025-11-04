locals {
  vpc_cidr = "10.0.0.0/16"
  cidr_blocks = cidrsubnets(local.vpc_cidr, 1, 1)
  cidrs = {
    public = cidrsubnets(local.cidr_blocks[0], [for _ in range(0, length(var.availability_zones)) : 1]...)
    private =  cidrsubnets(local.cidr_blocks[1], [for _ in range(0, length(var.availability_zones)) : 1]...)
  }
}

resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.this.id
  cidr_block = local.cidrs.public[each.key]
  availability_zone = each.value
  map_public_ip_on_launch = true

  for_each = { for i, v in var.availability_zones : i => v }
  tags = {
    Name = "${var.prefix}-${each.value}-public"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.prefix}-rtb-public"
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id = each.value.id
  for_each = { for i, v in aws_subnet.public : i => v }
}


resource "aws_subnet" "private" {
  vpc_id = aws_vpc.this.id
  cidr_block = local.cidrs.private[each.key]
  availability_zone = each.value

  for_each = { for i, v in var.availability_zones : i => v }
  tags = {
    Name = "${var.prefix}-${each.value}-private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.prefix}-rtb-private"
  }
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private.id
  subnet_id = each.value.id
  for_each = { for i, v in aws_subnet.private : i => v }
}

resource "aws_security_group" "endpoint" {
  name = "${var.prefix}-endpoint-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    protocol = "TCP"
    from_port = 443
    to_port = 443
  }

  tags = {
    Name = "${var.prefix}-endpoint-sg"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.region}.ssm"
  vpc_endpoint_type = "Interface"
  security_group_ids = [ aws_security_group.endpoint.id ]
  subnet_ids = [ for _, v in aws_subnet.private : v.id ]

  tags = {
    Name = "${var.prefix}-vpc-ssm-endpoint"
  }

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  security_group_ids = [ aws_security_group.endpoint.id ]
  subnet_ids = [ for _, v in aws_subnet.private : v.id ]

  tags = {
    Name = "${var.prefix}-vpc-ssmmessages-endpoint"
  }

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  security_group_ids = [ aws_security_group.endpoint.id ]
  subnet_ids = [ for _, v in aws_subnet.private : v.id ]

  tags = {
    Name = "${var.prefix}-vpc-ec2messages-endpoint"
  }

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.region}.kms"
  vpc_endpoint_type = "Interface"
  security_group_ids = [ aws_security_group.endpoint.id ]
  subnet_ids = [ for _, v in aws_subnet.private : v.id ]

  tags = {
    Name = "${var.prefix}-vpc-kms-endpoint"
  }

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3gateway" {
  vpc_id = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.region}.s3"

  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name = "${var.prefix}-vpc-s3-endpoint"
  }
}