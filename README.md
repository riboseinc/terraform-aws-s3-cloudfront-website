# Terraform module to set up a S3 Website with CloudFront, ACM

Current version

For old version, check [README-v2.md](README-v2.md)

Terraform version supported: 1.x

Sample site can can be found [here](sample-site)

## Update to AWS provider 4x

AWS Provider 4x is supported in terraform-aws-s3-cloudfront-website version 3x

1. Old code sample (v2x)
```terraform
# main.tf
module "main" {
  source = "../../terraform-aws-s3-cloudfront-website"

  fqdn                = var.fqdn
  ssl_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
  allowed_ips         = var.allowed_ips

  index_document = "index.html"
  error_document = "404.html"

  refer_secret = base64sha512("REFER-SECRET-19265125-${var.fqdn}-52865926")

  force_destroy = "true"

  providers = {
    aws.cloudfront = aws.cloudfront
    aws.main = aws.main
  }
}
```

2. New code sample (v3x)
```terraform
# main.tf

module "main" {
  source = "../../terraform-aws-s3-cloudfront-website"

  fqdn                = var.fqdn
  ssl_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
  allowed_ips         = var.allowed_ips

  index_document = "index.html"
  error_document = "404.html"

  refer_secret = base64sha512("REFER-SECRET-19265125-${var.fqdn}-52865926")

  force_destroy = "true"

  ## updated config
  routing_rule = {
    condition = {
      http_error_code_returned_equals = "401"
    }

    redirect = {
      host_name = "google.com"
    }
  }

  providers = {
    aws.cloudfront = aws.cloudfront
    aws.main = aws.main
  }
}
```
