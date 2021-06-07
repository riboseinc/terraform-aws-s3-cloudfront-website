output "s3_domain" {
  value = module.main.s3_website_endpoint
}

output "cloudfront_domain" {
  value = module.main.cf_domain_name
}

output "cloudfront_hosted_zone_id" {
  value = module.main.cf_hosted_zone_id
}

output "cloudfront_distribution_id" {
  value = module.main.cf_distribution_id
}

output "route53_fqdn" {
  value = aws_route53_record.web.fqdn
}

output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.cert.certificate_arn
}

