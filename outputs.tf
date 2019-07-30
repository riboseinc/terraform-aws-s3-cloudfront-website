output "s3_bucket_id" {
  value = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.main.arn
}

output "s3_website_endpoint" {
  # This doesn't work in terraform due to dependency issues:
  # https://github.com/terraform-providers/terraform-provider-aws/issues/1117
  # value = "${aws_s3_bucket.main.website_endpoint}"
  value = "${var.fqdn}.s3-website-${data.aws_region.main.name}.amazonaws.com"
}

output "s3_hosted_zone_id" {
  value = aws_s3_bucket.main.hosted_zone_id
}

output "cf_domain_name" {
  value = concat(
      aws_cloudfront_distribution.main-lambda-edge.*.domain_name,
      aws_cloudfront_distribution.main.*.domain_name,
    )[0]
}

output "cf_hosted_zone_id" {
  value = concat(
      aws_cloudfront_distribution.main-lambda-edge.*.hosted_zone_id,
      aws_cloudfront_distribution.main.*.hosted_zone_id,
    )[0]
}

output "cf_distribution_id" {
  value = concat(
      aws_cloudfront_distribution.main-lambda-edge.*.id,
      aws_cloudfront_distribution.main.*.id,
    )[0]
}

