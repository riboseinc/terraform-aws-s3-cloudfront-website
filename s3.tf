locals {
  localBucketName = var.bucket_name == null ? var.fqdn : var.bucket_name

  localRoutingRules = try(var.routing_rule, null) == null ? [] : [
    {
      condition = {
        http_error_code_returned_equals = try(var.routing_rule.condition.http_error_code_returned_equals, null)
        key_prefix_equals = try(var.routing_rule.condition.key_prefix_equals, null)
      }

      redirect = {
        host_name =  try(var.routing_rule.redirect.host_name, null)
        http_redirect_code =  try(var.routing_rule.redirect.http_redirect_code, null)
        protocol =  try(var.routing_rule.redirect.protocol, null)
        replace_key_prefix_with =  try(var.routing_rule.redirect.replace_key_prefix_with, null)
        replace_key_with =  try(var.routing_rule.redirect.replace_key_with, null)
      }
    }
  ]
}

#locals {
#  buckets = tomap({
#  for key, bucket in var.buckets : key => {
#    website = try(bucket.website, null) == null ? null : {
#      index_document = tostring(try(bucket.website.index_document, null))
#      error_document = tostring(try(bucket.website.error_document, null))
#    }
#    cors_rule = try(bucket.cors_rule, null) == null ? null : {
#      allowed_headers = toset(try(bucket.cors_rule.allowed_headers, ["X-Custom-Header"]))
#      allowed_methods = toset(try(bucket.cors_rule.allowed_methods, ["GET"]))
#      allowed_origins = toset(try(bucket.cors_rule.allowed_origins, ["*"]))
#      expose_headers  = toset(try(bucket.cors_rule.expose_headers, null))
#      max_age_seconds = tostring(try(bucket.cors_rule.max_age_seconds, null))
#    }
#  }
#  })
#}


resource "aws_s3_bucket_accelerate_configuration" "main" {
  count  = var.acceleration_status != null ? 1 : 0
  bucket = aws_s3_bucket.main.id
  status = var.acceleration_status
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  #  index_document = var.index_document
  #  error_document = var.error_document
  #  routing_rules = var.routing_rules

  dynamic "routing_rule" {
    for_each = local.localRoutingRules
    content {
      condition {
        http_error_code_returned_equals = routing_rule.value.condition.http_error_code_returned_equals
        key_prefix_equals = routing_rule.value.condition.key_prefix_equals
      }

      redirect {
        host_name = routing_rule.value.redirect.host_name
        http_redirect_code = routing_rule.value.redirect.http_redirect_code
        protocol = routing_rule.value.redirect.protocol
        replace_key_prefix_with = routing_rule.value.redirect.replace_key_prefix_with
        replace_key_with = routing_rule.value.redirect.replace_key_with
      }
    }
  }

#  routing_rule {
#    condition {
#      http_error_code_returned_equals = null
#      key_prefix_equals               = null
#    }
#
#    redirect {
#      host_name               = null
#      http_redirect_code      = null
#      protocol                = null
#      replace_key_prefix_with = null
#      replace_key_with        = null
#    }
#  }

#  dynamic "setting" {
#    for_each = var.settingscontent {
#      namespace = setting.value["namespace"]
#      name = setting.value["name"]
#      value = setting.value["value"]
#    }
#  }

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
  bucket   = local.localBucketName

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
    {
      "Name" = local.localBucketName
    },
    var.tags
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
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = var.allowed_ips
    }

    principals {
      type        = "*"
      identifiers = [
        "*"
      ]
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
      test     = "StringEquals"
      variable = "aws:UserAgent"

      values = [
        var.refer_secret,
      ]
    }

    principals {
      type        = "*"
      identifiers = [
        "*"
      ]
    }
  }
}

