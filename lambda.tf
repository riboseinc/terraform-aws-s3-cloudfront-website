module "lambda" {
  source = "lambda"

  bucket_name    = "${var.bucket_name}"
  bucket_key     = "${var.bucket_key}"
  basic_user     = "${var.basic_user}"
  basic_password = "${var.basic_password}"
}
