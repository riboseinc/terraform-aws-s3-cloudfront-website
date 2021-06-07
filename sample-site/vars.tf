# Variables
variable "fqdn" {
  description = "The fully-qualified domain name of the resulting S3 website."
}

# Allowed IPs that can directly access the S3 bucket
variable "allowed_ips" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

