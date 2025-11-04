resource "aws_security_group" "this" {
  name = "${var.prefix}-ec2-sg"
  vpc_id = aws_vpc.this.id
  

  tags = {
    name = "${var.prefix}-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_launch_template" "this" {
  name_prefix = "${var.prefix}-${data.aws_region.current.region}"
  image_id = "ami-02752bace93d57e53"
  instance_type = "t3.medium"

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags = "enabled"
  }

  user_data = base64encode(file("${path.module}/provision.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.prefix}-${data.aws_region.current.region}"
      Substituters = "s3://${aws_s3_bucket.nixstore.bucket}?region=${data.aws_region.current.region}&trusted=1"
      NixStorePath = "dummy-to-be-filled-in-later"
    }
  }

  network_interfaces {
    associate_public_ip_address = "false"
    security_groups = [aws_security_group.this.id]
  }

  tags = {
    Name = "${var.prefix}-launch-template"
  }

  lifecycle {
    ignore_changes = [ 
      tag_specifications[0].tags
     ]
  }
}

resource "aws_autoscaling_group" "this" {
  name_prefix = "${var.prefix}-${data.aws_region.current.region}"

  vpc_zone_identifier = [for _, v in aws_subnet.private : v.id]

  health_check_grace_period = 300
  health_check_type = "ELB"

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 110
    }
  }

  desired_capacity = 1
  max_size = 1
  min_size = 1

  launch_template {
    id = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = [ aws_lb_target_group.this.arn ]

  lifecycle {
    ignore_changes = [ 
      desired_capacity,
      max_size,
      min_size,
      launch_template[0].version
     ]
  }
}