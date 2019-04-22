variable "aws_region" {
    description = "Region for the VPC"
    default = "us-west-2"
}

variable "kinesis_stream_name" {
    description = "Name of Kinesis Stream"
    default = "stream-kinesis"
}