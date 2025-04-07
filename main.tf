terraform {
  backend "s3" {
    bucket = "joseph-sctps3bucket" # "sctp-ce9-tfstate"
    key    = "joseph03-wk18-3.1"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}


data "aws_caller_identity" "current" {}

locals {
  #name_prefix = split("/", "${data.aws_caller_identity.current.arn}")[1]
  # change data.aws_coller to clear TFlin error
  name_prefix = split("/", data.aws_caller_identity.current.arn[1])
  account_id  = data.aws_caller_identity.current.account_id
}
terraform {
  required_version = ">= 1.0"
}

resource "aws_s3_bucket" "s3_tf" {
  bucket = "${local.name_prefix}-s3-tf-bkt-${local.account_id}"
}
