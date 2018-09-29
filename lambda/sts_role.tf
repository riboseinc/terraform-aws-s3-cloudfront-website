data "aws_iam_policy_document" "sts" {
  statement {
    effect  = "Allow",
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    effect    = "Allow",
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role_policy" "this" {
  name = "${local.name}"
  role        = "${aws_iam_role.this.id}"
  policy      = "${data.aws_iam_policy_document.this.json}"
}

resource "aws_iam_role" "this" {
  name = "${local.name}"
  assume_role_policy = "${data.aws_iam_policy_document.sts.json}"
}

