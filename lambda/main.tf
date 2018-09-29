locals {
  name = "lambda-basic-auth-s3-cloudfront-website"
}

resource "template_dir" "this" {
  source_dir      = "${path.module}/src"
  destination_dir = "${path.module}/.archive"
}

data "archive_file" "this" {
  depends_on  = [
    "template_dir.this"
  ]
  type        = "zip"
  output_path = "${path.module}/.archive.zip"
  source_dir  = "${template_dir.this.destination_dir}"
}

resource "aws_lambda_function" "this" {
  description      = "Basic HTTP authentication module/function"
  role             = "${aws_iam_role.this.arn}"
  runtime          = "nodejs8.10"

  filename         = "${data.archive_file.this.output_path}"
  source_code_hash = "${data.archive_file.this.output_base64sha256}"

  function_name    = "${local.name}"
  handler          = "handler"

  timeout          = "300" # ~5mins

  lifecycle {
    ignore_changes = [
      "last_modified",
      "source_code_hash"
    ]
  }
}
