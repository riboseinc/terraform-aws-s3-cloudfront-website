terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.0"
      configuration_aliases = [aws.main, aws.cloudfront]
    }
  }
}
//configuration_aliases = [ aws.alternate ]
