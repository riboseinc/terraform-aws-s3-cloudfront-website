# Terraform doesn't allow specifying required providers yet, but this
# is placed here in case it is allowed:
# https://github.com/hashicorp/terraform/issues/17191
provider "aws" {
  alias = "main"
}

#
provider "aws" {
  alias = "cloudfront"
}

