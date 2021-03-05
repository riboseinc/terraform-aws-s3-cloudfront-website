locals {
  localBucketName = var.bucketName == null ? var.fqdn : var.bucketName
}

resource "aws_s3_bucket" "main" {
  provider = aws.main
  bucket = local.localBucketName

  acl = "private"
  policy = data.aws_iam_policy_document.bucket_policy.json

  website {
    index_document = var.index_document
    error_document = var.error_document
    routing_rules = var.routing_rules
  }

  force_destroy = var.force_destroy

  # Transfer acceleration is not possible right now for hosted sites,
  # as bucket names cannot contain a dot.
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html
  acceleration_status = var.acceleration_status

  tags = merge(
  var.tags,
  {
    "Name" = var.fqdn
  },
  )
}

data "aws_iam_policy_document" "bucket_policy" {
  provider = aws.main

  statement {
    sid = "AllowedIPReadAccess"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.localBucketName}/*",
    ]

    condition {
      test = "IpAddress"
      variable = "aws:SourceIp"

      values = var.allowed_ips
    }

    principals {
      type = "*"
      identifiers = [
        "*"]
    }
  }

  statement {
    sid = "AllowCFOriginAccess"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.localBucketName}/*",
    ]

    condition {
      test = "StringEquals"
      variable = "aws:UserAgent"

      values = [
        var.refer_secret,
      ]
    }

    principals {
      type = "*"
      identifiers = [
        "*"]
    }
  }
}

