locals {
  name = "lambda-basic-auth-s3-cloudfront-website"
}

resource "template_dir" "this" {
  source_dir      = "${path.module}/src"
  destination_dir = "${path.module}/.archive"

  vars {
    BUCKET_NAME = "${var.bucket_name}"
    BUCKET_KEY  = "${var.bucket_key}"

    BASIC_USER = "${var.basic_user}"
    BASIC_PWD  = "${var.basic_password}"
  }
}

data "archive_file" "this" {
  depends_on = [
    "template_dir.this",
  ]

  type        = "zip"
  output_path = "${path.module}/.archive.zip"
  source_dir  = "${template_dir.this.destination_dir}"
}

resource "aws_lambda_function" "this" {
  description = "Basic HTTP authentication module/function"
  role        = "${aws_iam_role.this.arn}"
  runtime     = "nodejs8.10"

  filename         = "${data.archive_file.this.output_path}"
  source_code_hash = "${data.archive_file.this.output_base64sha256}"

  function_name = "${local.name}"
  handler       = "basic_auth.handler"

  timeout     = "3"
  memory_size = 128
  publish     = true
}
