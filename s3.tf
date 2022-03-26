locals {
  localBucketName = var.bucket_name == null ? var.fqdn : var.bucket_name
}


resource "aws_s3_bucket_accelerate_configuration" "main" {
  count = var.acceleration_status != null ? 1 : 0
  bucket = aws_s3_bucket.main.id
  status = var.acceleration_status
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl = "private"
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id
#  index_document = var.index_document
#  error_document = var.error_document
#  routing_rules = var.routing_rules

  routing_rule {
    condition {
      http_error_code_returned_equals = ''
      key_prefix_equals = ''
    }

    redirect {
      host_name = ''
      http_redirect_code = ''
      protocol = ''
      replace_key_prefix_with= ''
      replace_key_with = ''
    }
  }

  index_document {
    suffix = var.index_document
  }
  error_document {
    key = "error.html"
  }

#  routing_rule = var.routing_rules

#  index_document {
#    suffix = "index.html"
#  }
#
#  error_document {
#    key = "error.html"
#  }
}

resource "aws_s3_bucket" "main" {
  provider = aws.main
  bucket = local.localBucketName

#  acl = "private"
#  policy = data.aws_iam_policy_document.bucket_policy.json

#  website {
#    index_document = var.index_document
#    error_document = var.error_document
#    routing_rules = var.routing_rules
#  }

  force_destroy = var.force_destroy

  # Transfer acceleration is not possible right now for hosted sites,
  # as bucket names cannot contain a dot.
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html
#  acceleration_status = var.acceleration_status

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
      "s3:GetObsject",
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

