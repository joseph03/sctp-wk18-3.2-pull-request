#-- notification
resource "aws_sns_topic" "bucket_notifications" {
  name = "${local.name_prefix}-bucket-notification"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.s3_tf.id

  topic {
    topic_arn     = aws_sns_topic.bucket_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "logs/"
  }
}

#-- encrypt
resource "aws_s3_bucket_server_side_encryption_configuration" "good_sse_1" {
  bucket = aws_s3_bucket.s3_tf.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

#-- public access block
resource "aws_s3_bucket_public_access_block" "access_good_1" {
  bucket = aws_s3_bucket.s3_tf.id

  block_public_acls   = true
  block_public_policy = true
}

#-- versioning
resource "aws_s3_bucket_versioning" "s3_version" {
  bucket = aws_s3_bucket.s3_tf.id

  versioning_configuration {
    status = "Enabled"
  }
}

#-- cross region
resource "aws_s3_bucket_versioning" "east" {
  bucket = aws_s3_bucket.s3_tf.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "west" {
  provider = aws.west
  bucket   = "${local.name_prefix}-s3-west-${local.account_id}"
}

resource "aws_s3_bucket_versioning" "west" {
  provider = aws.west

  bucket = aws_s3_bucket.west.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "east_to_west" {
  depends_on = [aws_s3_bucket_versioning.east]
  role       = aws_iam_role.east_replication.arn
  bucket     = aws_s3_bucket.s3_tf.id

  rule {
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.west.arn
      storage_class = "STANDARD"
    }
  }
}


#-- logging
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${local.name_prefix}-log-bucket-${local.account_id}"
}

# Enable default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "s3_log" {
  bucket = aws_s3_bucket.s3_tf.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

#-- lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "s3_tf_lifecycle" {
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}

