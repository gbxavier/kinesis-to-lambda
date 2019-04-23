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