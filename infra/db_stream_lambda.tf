resource "aws_lambda_event_source_mapping" "db_stream_lambda" {
  event_source_arn  = aws_dynamodb_table.event_table.stream_arn
  function_name     = aws_lambda_function.db_stream_reader.function_name
  starting_position = "LATEST"
}

data "aws_s3_object" "db_stream_reader" {
  bucket = "${terraform.workspace}-core-lambda-bucket"
  key    = "lambdas/db_stream_reader.zip"
}

resource "aws_lambda_function" "db_stream_reader" {
  function_name    = "db_stream_reader"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  s3_bucket        = "${terraform.workspace}-core-lambda-bucket"
  s3_key           = "lambdas/db_stream_reader.zip"
  source_code_hash = data.aws_s3_object.db_stream_reader.etag
  role             = aws_iam_role.db_stream_lambda.arn
  layers           = [aws_lambda_layer_version.aws_sdk_layer.arn]
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.event_table.name
    }
  }
}

resource "aws_iam_role" "db_stream_lambda" {
  name               = "db_stream_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "db_stream_lambda" {
  role = aws_iam_role.db_stream_lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource : "*"
      }
    ]
  })
}
