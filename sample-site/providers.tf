provider "aws" {
  alias = "main"
  region = "us-east-1"
#  version = "~>4.0"
}

provider "aws" {
  alias = "cloudfront"
  region = "us-east-1"
}

