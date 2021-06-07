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

