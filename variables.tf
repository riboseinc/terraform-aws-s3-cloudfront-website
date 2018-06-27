variable "fqdn" {
  type        = "string"
  description = "The FQDN of the website and also name of the S3 bucket"
}

variable "force_destroy" {
  type        = "string"
  description = "The force_destroy argument of the S3 bucket"
  default     = "false"
}

variable ssl_certificate_arn {
  type        = "string"
  description = "ARN of the certificate covering the fqdn and its apex?"
}

variable "allowed_ips" {
  type        = "list"
  description = "A list of IPs that can access the S3 bucket directly"
  default     = []
}

variable "web_acl_id" {
  type        = "string"
  description = "WAF Web ACL ID to attach to the CloudFront distribution, optional"
  default     = ""
}

variable "refer_secret" {
  type        = "string"
  description = "A secret string to authenticate CF requests to S3"
  default    = "123-VERY-SECRET-123"
}

variable routing_rules {
  type        = "string"
  description = "Routing rules for the S3 bucket"
  default     = ""
}

variable index_document {
  type        = "string"
  description = "HTML to show at root"
  default     = "index.html"
}

variable error_document {
  type        = "string"
  description = "HTML to show on 404"
  default     = "404.html"
}

variable "tags" {
  type        = "map"
  description = "Tags"
  default     = {}
}
