variable "aws_region" {
    description = "Region for the VPC"
    default = "us-west-2"
}

variable "kinesis_stream_name" {
    description = "Name of Kinesis Stream"
    default = "stream-kinesis"
}

variable "s3_archive_bucket_name" {
    description = "Name of S3 Bucket used for archive records"
    default = "kinesis-archive-20190422"
}

variable "dynamoDB_table_name" {
    description = "DynamoDB read capacity"
    default = "dynamo-stream-table"
}

variable "dynamoDB_read_capacity" {
    description = "DynamoDB read capacity"
    default = "20"
}

variable "dynamoDB_write_capacity" {
    description = "DynamoDB write capacity"
    default = "20"
}

variable "dynamoDB_hash_key" {
    description = "DynamoDB table's hash key"
    default = "payload"
}

variable "dynamoDB_range_key" {
    description = "DynamoDB table's range key"
    default = "ts"
}
