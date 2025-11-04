resource "aws_lb" "this" {
  name = "${var.prefix}-lb"

  load_balancer_type = "network"
  security_groups = [
    aws_security_group.this.id
  ]

  subnets = [for _, v in aws_subnet.public : v.id]

  enable_deletion_protection = true
  tags = {
    Name = "${var.prefix}-lb"
  }
}

resource "aws_lb_target_group" "this" {
  name = "${var.prefix}-lb-tg"
  port = 443
  protocol = "TCP"
  vpc_id = aws_vpc.this.id

  health_check {
    enabled = true
    matcher = "200"
    path = "/health"
    protocol = "HTTPS"
  }

  tags = {
    Name = "${var.prefix}-lb-tg"
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port = 443
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = {
    Name = "${var.prefix}-lb-listener"
  }
}