# Terraform doesn't allow specifying required providers yet, but this
# is placed here in case it is allowed:
# https://github.com/hashicorp/terraform/issues/17191

# provider "aws" {
#   alias = "main"
#   description = "AWS Region for S3 and other resources"
# }
#
# provider "aws" {
#   alias = "cloudfront"
#   description = "AWS Region for Cloudfront (ACM certs only supports us-east-1)"
# }
