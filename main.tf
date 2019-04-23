provider "aws" {
    version = "~> 2.0.0"
    region = "${var.aws_region}"
}
provider "archive" {
    version = "~> 1.2"
}


## IAM Role for Lambda Function
resource "aws_iam_role" "iam_for_terraform_lambda" {
    name = "kinesis_streamer_iam_role"
    description = "Role for kinesis usage"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

## IAM Role Policies

resource "aws_iam_policy" "lambda_stream_policy" {
  name        = "LambdaStreamPolicy"
  description = "Provides InvokeFunction access to the Lambda Created for Kinesis"
  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.kinesis_consumer.arn}"
    },
    {
      "Action": [
        "dynamodb:PutItem"
      ],
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.stream-dynamodb-table.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_basic_execution" {
  role = "${aws_iam_role.iam_for_terraform_lambda.id}"
  policy_arn = "${aws_iam_policy.lambda_stream_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_kinesis_execution" {
  role = "${aws_iam_role.iam_for_terraform_lambda.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
}


## Kinesis Stream
resource "aws_kinesis_stream" "test_stream" {
  name             = "${var.kinesis_stream_name}"
  shard_count      = 1
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = {
    Environment = "stream-test"
  }
}

## Lambda

data "archive_file" "consumer_lambda" {
  type = "zip"
  source_dir = "./consumer"
  output_path = "./build/consumer.zip"
}

resource "aws_lambda_function" "kinesis_consumer" {
  filename = "${data.archive_file.consumer_lambda.output_path}"
  function_name = "${var.kinesis_stream_name}_consumer"
  description = "This function consume Kinesis stream data."
  role = "${aws_iam_role.iam_for_terraform_lambda.arn}"
  handler = "consumer.handler_kinesis"
  runtime = "python3.7"
  source_code_hash = "${filebase64sha256("${data.archive_file.consumer_lambda.output_path}")}"
  timeout = 300 # 5 mins

  environment = {
    variables = {
      s3_bucket = "${aws_s3_bucket.lambda_archive.bucket}"
      dynamodb_table = "${aws_dynamodb_table.stream-dynamodb-table.name}"
    }
  }
}

resource "aws_lambda_event_source_mapping" "kinesis_lambda_event_mapping" {
    batch_size = 100
    event_source_arn = "${aws_kinesis_stream.test_stream.arn}"
    enabled = true
    function_name = "${aws_lambda_function.kinesis_consumer.arn}"
    starting_position = "TRIM_HORIZON"
}

## S3 Bucket

resource "aws_s3_bucket" "lambda_archive" {
  bucket = "${var.s3_archive_bucket_name}"
  acl    = "private"

  tags = {
    Name = "S3 Bucket to archive records"
  }
}

resource "aws_s3_bucket_policy" "lambda_archive" {
  bucket = "${aws_s3_bucket.lambda_archive.bucket}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "LambdaArchivePolicy",
  "Statement": [
    {
      "Sid": "Stmt1555978089647",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.lambda_archive.arn}/*"
    }
  ]
}
POLICY
}

## DynamoDB

resource "aws_dynamodb_table" "stream-dynamodb-table" {
  name           = "${var.dynamoDB_table_name}"
  read_capacity  = "${var.dynamoDB_read_capacity}"
  write_capacity = "${var.dynamoDB_write_capacity}"
  hash_key       = "${var.dynamoDB_hash_key}"
  range_key      = "${var.dynamoDB_range_key}"

  attribute {
    name = "payload"
    type = "S"
  }

  attribute {
    name = "ts"
    type = "S"
  }

}
