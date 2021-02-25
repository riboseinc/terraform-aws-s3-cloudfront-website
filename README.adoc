= Terraform module to setup a S3 Website with CloudFront, ACM

This module helps you create a S3 website, assuming that:

* it runs HTTPS via Amazon's Certificate Manager ("ACM")
* its domain is backed by a Route53 zone
* and of course, your AWS account provides you access to all these resources necessary.

This module is available on the https://registry.terraform.io/modules/riboseinc/s3-cloudfront-website/aws/[Terraform Registry].

This module is a pair with
https://github.com/riboseinc/terraform-aws-s3-cloudfront-redirect[terraform-aws-s3-cloudfront-redirect],
which handles redirecting of a DNS hostname to a website, using S3, CloudFront and ACM.

== Sample Usage

You can literally copy and paste the following example, change the following attributes, and you're ready to go:

* `allowed_ips`: set it to "`0.0.0.0/0`" if it should be publicly accessible
* `fqdn`: set to your static website's hostname
* `domain`: set to your static website's base domain name (e.g., `xyz.com`)
* `cf_ipv6_enabled`: default is `true`,
enable https://aws.amazon.com/about-aws/whats-new/2016/10/ipv6-support-for-cloudfront-waf-and-s3-transfer-acceleration/[CloudFront IPV6] feature.
* `single_page_application`: default is `false`. If `true`, redirects all `404 errors` to the specified `index_document` variable.


[source,hcl]
----
# AWS Region for S3 and other resources
provider "aws" {
  region = "us-west-2"
  alias = "main"
}

# AWS Region for Cloudfront (ACM certs only supports us-east-1)
provider "aws" {
  region = "us-east-1"
  alias = "cloudfront"
}

# Variables
variable "fqdn" {
  description = "The fully-qualified domain name of the resulting S3 website."
  default     = "mysite.example.com"
}

variable "domain" {
  description = "The domain name."
  default     = "example.com"
}

# Allowed IPs that can directly access the S3 bucket
variable "allowed_ips" {
  type = "list"
  default = [
    "0.0.0.0/0"            # public access
    # "xxx.xxx.xxx.xxx/mm" # restricted
    # "999.999.999.999/32" # invalid IP, completely inaccessible
  ]
}

# Using this module
module "main" {
  source = "github.com/riboseinc/terraform-aws-s3-cloudfront-website"

  fqdn = "${var.fqdn}"
  ssl_certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"
  allowed_ips = "${var.allowed_ips}"

  index_document = "index.html"
  error_document = "404.html"

  refer_secret = "${base64sha512("REFER-SECRET-19265125-${var.fqdn}-52865926")}"

  force_destroy = "true"

  # Optional override for PriceClass, defaults to PriceClass_100
  cloudfront_price_class = "PriceClass_200"

  providers = {
    aws.main = aws.main
    aws.cloudfront = aws.cloudfront
  }

  # Optional WAF Web ACL ID, defaults to none.
  web_acl_id = "${data.terraform_remote_state.site.waf-web-acl-id}"
}


# ACM Certificate generation

resource "aws_acm_certificate" "cert" {
  provider          = "aws.cloudfront"
  domain_name       = "${var.fqdn}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  provider = "aws.cloudfront"
  name     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id  = "${data.aws_route53_zone.main.id}"
  records  = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = "aws.cloudfront"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}


# Route 53 record for the static site

data "aws_route53_zone" "main" {
  provider     = "aws.main"
  name         = "${var.domain}"
  private_zone = false
}

resource "aws_route53_record" "web" {
  provider = "aws.main"
  zone_id  = "${data.aws_route53_zone.main.zone_id}"
  name     = "${var.fqdn}"
  type     = "A"

  alias {
    name    = "${module.main.cf_domain_name}"
    zone_id = "${module.main.cf_hosted_zone_id}"
    evaluate_target_health = false
  }
}

# Outputs

output "s3_bucket_id" {
  value = "${module.main.s3_bucket_id}"
}

output "s3_bucket_arn" {
  value = "${module.main.s3_bucket_arn}"
}

output "s3_domain" {
  value = "${module.main.s3_website_endpoint}"
}

output "s3_hosted_zone_id" {
  value = "${module.main.s3_hosted_zone_id}"
}

output "cloudfront_domain" {
  value = "${module.main.cf_domain_name}"
}

output "cloudfront_hosted_zone_id" {
  value = "${module.main.cf_hosted_zone_id}"
}

output "cloudfront_distribution_id" {
  value = "${module.main.cf_distribution_id}"
}

output "route53_fqdn" {
  value = "${aws_route53_record.web.fqdn}"
}

output "acm_certificate_arn" {
  value = "${aws_acm_certificate_validation.cert.certificate_arn}"
}
----


== Supporting bare domains and redirects


=== Domain aliases

Need to support a bare domain, e.g. `example.com`, and a `www.example.com`?

Set `fqdn` to the bare domain and set up a record for the `www`:

[source,hcl]
----
resource "aws_route53_record" "www" {
  provider = "aws.main"
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name = "www.${var.fqdn}"
  type = "CNAME"
  records = ["${var.fqdn}"]
  ttl = 300
}

# add this inside module "main" under fqdn:
aliases             = "www.${var.fqdn}"
----


=== Redirecting from the bare domain to www (and vice versa)

You can use the sister module to this,
https://github.com/riboseinc/terraform-aws-s3-cloudfront-redirect[terraform-aws-s3-cloudfront-redirect],
to implement a redirect from/to `example.com` to `https://www.example.com`
(or vice versa if you want to).

In the following code,

* set `fqdn-root` as your root domain, and `fqdn-main` as its redirect target;
* it also requests a proper ACM certificate for the `fqdn-root` hostname.

[source,hcl]
----
module "site-root" {
  source = "github.com/riboseinc/terraform-aws-s3-cloudfront-redirect"

  fqdn                = "${var.fqdn-root}"
  redirect_target     = "${var.fqdn-main}"
  ssl_certificate_arn = "${aws_acm_certificate_validation.cert-root.certificate_arn}"

  refer_secret = "${base64sha512("SUPER-REFER-SECRET${var.fqdn-root}*AGAIN")}"

  force_destroy = "true"

  providers = {
    aws.main       = aws.main
    aws.cloudfront = aws.cloudfront
  }
}

resource "aws_route53_record" "web-root" {
  provider = "aws.main"
  zone_id  = "${data.aws_route53_zone.main.zone_id}"
  name     = "${var.fqdn-root}"
  type     = "A"

  alias {
    name                   = "${module.site-root.cf_domain_name}"
    zone_id                = "${module.site-root.cf_hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert-root" {
  provider          = "aws.cloudfront"
  domain_name       = "${var.fqdn-root}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation-root" {
  provider = "aws.cloudfront"
  name     = "${aws_acm_certificate.cert-root.domain_validation_options.0.resource_record_name}"
  type     = "${aws_acm_certificate.cert-root.domain_validation_options.0.resource_record_type}"
  zone_id  = "${data.aws_route53_zone.main.id}"
  records  = ["${aws_acm_certificate.cert-root.domain_validation_options.0.resource_record_value}"]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "cert-root" {
  provider                = "aws.cloudfront"
  certificate_arn         = "${aws_acm_certificate.cert-root.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation-root.fqdn}"]
}
----


== Supporting path redirects

The `routing_rules` variable allows setting path redirection rules
according to
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-websiteconfiguration-routingrules.html[AWS S3 Routing Rules].

This variable only accepts JSON input, as described in the
https://www.terraform.io/docs/providers/aws/r/s3_bucket.html[Terraform aws_s3_bucket page].

In the following example, the S3 website will redirect paths
matching prefix `myprefix/` to `https://www.example.com` with
the HTTP status code `302`.

[source,hcl]
----
module "site-root" {
  source = "github.com/riboseinc/terraform-aws-s3-cloudfront-redirect"

  fqdn                = "${var.fqdn-root}"
  ssl_certificate_arn = "${aws_acm_certificate_validation.cert-root.certificate_arn}"

  refer_secret = "${base64sha512("SUPER-REFER-SECRET${var.fqdn-root}*AGAIN")}"

  force_destroy = "true"

  routing_rules = <<EOF
  [{
    "Condition": {
      "KeyPrefixEquals": "myprefix/"
    },
    "Redirect": {
      "HostName": "www.example.com",
      "HttpRedirectCode": "302",
      "Protocol": "https"
    }
  }]
EOF

  providers = {
    aws.main       = aws.main
    aws.cloudfront = aws.cloudfront
  }
}
----


== Supporting HTTP authentication

This module supports configuration for HTTP authentication using the sister module
https://github.com/riboseinc/terraform-aws-lambda-edge-authentication[terraform-aws-lambda-edge-authentication].

NOTE: This authentication method utilizes AWS Lambda -- a paid resource.
Keep this in mind when adopting this solution.

This module works through applying an AWS Lambda HTTP authentication function
to the CloudFront@Edge distribution of the static website.

Specifically, this Lambda function is executed on every access to the site to check whether:

. the path being access should be protected
. if so, authenticate the client:
.. if the client was previously authentication (and therefore carries a cookie), allow
.. with an HTTP authentication, if it matches the configuration, allow
. if the client is allowed, place (or update) the cookie to allow for further access.

This is an example of how to use HTTP authentication with this module.

Assume you want to create a user called `foobar` with a password `FooBar#PassW0RD`.

Run `htaccess` to generate access credentials to upload:

[source,sh]
----
$ htpasswd -nbB foobar FooBar#PassW0RD
foobar:$2y$05$1h9cwwFusLcZCIUpdM7Gke.ei1E2QV6ORH/ZmvbR4h2tDGHb7q8lW
----

NOTE: This command uses `bcrypt` to store the password hash. While it is
the best choice out of available `htpasswd` algorithms (MD5, SHA1, crypt),
remember that by default there is no rate limiting on the Lambda function
-- meaning that someone can brute force the passwords via the public interface.
(You could use the `reserved_concurrent_executions` option to limit
Lambda concurrency.)

Create a configuration JSON file that specifies the paths to protect and
access credentials:

[source,js]
----
{
  /* store usernames and password in "htpasswd" format */
  "htpasswd": "foobar:$apr1$MlPn1Wl/$Tx5TGdU4YBfLQ5rudfu1j1",

  /* path patterns to protect in micromatch syntax */
  "uriPatterns": [

    /* all files that end with `.png` or `.sh` in the first level */
    "/*.{png,sh}",

    /* all files regardless of depth */
    "**"
  ]
}
----

NOTE: See
https://github.com/riboseinc/terraform-aws-lambda-edge-authentication[terraform-aws-lambda-edge-authentication]
on how to create blacklists and whitelists for path patterns.



Create an S3 bucket and upload the configuration JSON file:

[source,hcl]
----
provider "aws" {
  region = "us-east-1"
  #description = "AWS Region for Cloudfront (ACM certs only supports us-east-1)"
  alias = "cloudfront"
}

resource "aws_s3_bucket_object" "permissions" {
  bucket = "${aws_s3_bucket.permissions.bucket}"
  key    = "site-permissions.json"
  source = "./site-permissions.json"
  etag = "${filemd5("./site-permissions.json")}"
  provider = "aws.cloudfront"
}

resource "aws_s3_bucket" "permissions" {
  bucket = "my-site-permissions"
  acl    = "private"
  provider = "aws.cloudfront"
}
----

NOTE: Be aware that this S3 bucket (and the CloudFront@Edge Lambda function)
must be in the same region as CloudFront distribution. +
If you use AWS Certificate Manager (ACM) with CloudFront --
you must have BOTH the ACM certificate and the CloudFront distribution
created in the `us-east-1` region.
(https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html)
The same goes for the Lambda function and its configuration JSON file.


Create the authentication Lambda function. Remember that it must
use the same provider (same region) as the S3 bucket did.

[source,hcl]
----
module "staging-lambda" {
  source = "github.com/riboseinc/terraform-aws-lambda-edge-authentication"
  bucketName = "${aws_s3_bucket.permissions.bucket}"
  bucketKey = "${aws_s3_bucket_object.permissions.key}"
  cookieDomain = "${var.fqdn-staging}"

  providers = {
    aws = aws.cloudfront
  }
}
----


At last add the Lambda function to the site module:


[source,hcl]
----
module "site-root" {
  source = "github.com/riboseinc/terraform-aws-s3-cloudfront-redirect"

  fqdn                = "${var.fqdn-root}"
  ssl_certificate_arn = "${aws_acm_certificate_validation.cert-root.certificate_arn}"

  refer_secret = "${base64sha512("SUPER-REFER-SECRET${var.fqdn-root}*AGAIN")}"

  force_destroy = "true"

  lambda_edge_enabled = "true"
  lambda_edge_arn_version = "${module.staging-lambda.arn}:${module.staging-lambda.version}"

  providers = {
    aws.main       = aws.main
    aws.cloudfront = aws.cloudfront
  }

}
----


Now run `terraform apply` and see everything being setup.


To confirm this works:

. Visit a protected path in the browser and confirm that HTTP authentication
  is required. (You'll be prompted to log in.)

. Visit a protected path again in a browser, but this time with caches disabled.
  Check whether a cookie has been set in your request -- it should have been
  set in the previous successful authentication. It's working properly if you
  see it.

How awesome is this!


== Upgrading to Terraform 0.12

This module now supports Terraform 0.12.

To upgrade to Terraform 0.12 using this module, do this:

[source,bash]
----
terraform init -upgrade
terraform 0.12upgrade
terraform plan
terraform apply -auto-approve
----
