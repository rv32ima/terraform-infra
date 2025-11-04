resource "aws_s3_bucket" "nixstore" {
  bucket_prefix = "${var.prefix}-nix-store"
  force_destroy = true
  tags = {
    Name = "${var.prefix}-nix-store"
  }
}

data "aws_iam_policy_document" "nixstore" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }

    actions = [
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      aws_s3_bucket.nixstore.arn,
      "${aws_s3_bucket.nixstore.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "nixstore" {
  bucket = aws_s3_bucket.nixstore.id
  policy = data.aws_iam_policy_document.nixstore.json
}