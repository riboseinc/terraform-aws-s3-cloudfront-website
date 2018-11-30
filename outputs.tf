output "s3_bucket_id" {
  value = "${aws_s3_bucket.main.id}"
}

output "s3_website_endpoint" {
  # This doesn't work in terraform due to dependency issues:  # https://github.com/terraform-providers/terraform-provider-aws/issues/1117  # value = "${aws_s3_bucket.main.website_endpoint}"

  value = "${var.fqdn}.s3-website-${data.aws_region.main.name}.amazonaws.com"
}

output "s3_hosted_zone_id" {
  value = "${aws_s3_bucket.main.hosted_zone_id}"
}

output "cf_domain_name" {
  value = "${aws_cloudfront_distribution.main.0.domain_name}"
}

output "cf_hosted_zone_id" {
  value = "${aws_cloudfront_distribution.main.0.hosted_zone_id}"
}

output "cf_distribution_id" {
  value = "${aws_cloudfront_distribution.main.0.id}"
}
