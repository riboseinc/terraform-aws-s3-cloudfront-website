# ACM Certificate generation
resource "aws_acm_certificate" "cert" {
  provider          = aws.cloudfront
  domain_name       = var.fqdn
  validation_method = "DNS"
}

//resource "aws_route53_record" "cert_validation" {
//  provider = aws.cloudfront
//  name     = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
//  type     = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
//  records  = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
//  zone_id  = data.aws_route53_zone.main.id
//  ttl      = 60
//
//  depends_on = [data.aws_route53_zone.main]
//}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.cloudfront
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route 53 record for the static site

data "aws_route53_zone" "main" {
  provider     = aws.main
  name         = "booppi.website"
  private_zone = false
}

resource "aws_route53_record" "web" {
  provider = aws.main
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = var.fqdn
  type     = "A"

  alias {
    name                   = module.main.cf_domain_name
    zone_id                = module.main.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

