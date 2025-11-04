# data "aws_iam_policy_document" "this" {
# }

# resource "aws_iam_policy" "this" {
#   name = "${var.prefix}-ec2-policy"
#   policy = data.aws_iam_policy_document.this.json
#   tags = {
#     Name = "${var.prefix}-ec2-policy"
#   }
# }

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [ "sts:AssumeRole" ]
  }
}

resource "aws_iam_role" "this" {
  name = "${var.prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = {
    Name = "${var.prefix}-ec2-role"
  }
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.prefix}-ec2-instance-profile"
  role = aws_iam_role.this.id
  tags = {
    Name = "${var.prefix}-ec2-instance-profile"
  }
}