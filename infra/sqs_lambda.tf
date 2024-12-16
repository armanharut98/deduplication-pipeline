data "aws_s3_object" "layer" {
  bucket = "${terraform.workspace}-core-lambda-bucket"
  key    = "lambdas/aws_sdk.zip"
}

data "aws_s3_object" "lambda" {
  bucket = "${terraform.workspace}-core-lambda-bucket"
  key    = "lambdas/dedup_lambda.zip"
}

resource "aws_lambda_layer_version" "aws_sdk_layer" {
  layer_name          = "aws_sdk_layer"
  s3_bucket           = "dev-core-lambda-bucket"
  s3_key              = "lambdas/aws_sdk.zip"
  source_code_hash    = data.aws_s3_object.layer.etag
  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = aws_sqs_queue.event_queue.arn
  function_name    = aws_lambda_function.dedup.arn
}

resource "aws_lambda_function" "dedup" {
  function_name    = "dedup"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  s3_bucket        = "${terraform.workspace}-core-lambda-bucket"
  s3_key           = "lambdas/dedup_lambda.zip"
  source_code_hash = data.aws_s3_object.lambda.etag
  role             = aws_iam_role.iam_for_lambda.arn
  layers           = [aws_lambda_layer_version.aws_sdk_layer.arn]
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.event_table.name
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "lambda" {
  role = aws_iam_role.iam_for_lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables",
          "dynamodb:UpdateItem",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}
