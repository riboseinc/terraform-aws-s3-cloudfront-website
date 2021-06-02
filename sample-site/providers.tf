provider "aws" {
  alias = "main"
  region = "us-east-1"
}

provider "aws" {
  alias = "cloudfront"
  region = "us-east-1"
}

