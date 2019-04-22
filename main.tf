provider "aws" {
    version = "~> 2.0.0"
    region = "${var.aws_region}"
}
provider "archive" {
    version = "~> 1.2"
}


## IAM Role
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

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_basic_execution" {
  role = "${aws_iam_role.iam_for_terraform_lambda.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
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
}

resource "aws_lambda_event_source_mapping" "kinesis_lambda_event_mapping" {
    batch_size = 100
    event_source_arn = "${aws_kinesis_stream.test_stream.arn}"
    enabled = true
    function_name = "${aws_lambda_function.kinesis_consumer.arn}"
    starting_position = "TRIM_HORIZON"
}
