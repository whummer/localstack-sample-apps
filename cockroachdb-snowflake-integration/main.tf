# provider "aws" {
#   region     = "eu-central-1"
#   access_key = "fake"
#   secret_key = "fake"
#
#   skip_credentials_validation = true
#   skip_metadata_api_check     = true
#   skip_requesting_account_id  = true
#   s3_use_path_style           = true
#
#   endpoints {
#     s3  = "http://localhost:4566"
#     iam = "http://localhost:4566"
#   }
#
#   default_tags {
#     tags = {
#       Environment = "Local"
#       Service     = "LocalStack"
#     }
#   }
# }

#
# #############
# # S3 Bucket #
# #############
# resource "aws_s3_bucket" "crdb_to_snowflake_demo" {
#   bucket = "crdb-to-snowflake-cdc-demo"
# }
#
# ########
# # User #
# ########
# resource "aws_iam_user" "crdb_to_snowflake" {
#   name = "crdb-to-snowflake"
# }
#
# resource "aws_iam_user_policy" "crdb_to_snowflake" {
#   name   = "crdb-to-snowflake"
#   user   = aws_iam_user.crdb_to_snowflake.name
#   policy = <<-EOF
#   {
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Action" : "*",
#         "Resource" : "*"
#       }
#     ]
#   }
#   EOF
# }
#
# resource "aws_iam_access_key" "crdb_to_snowflake" {
#   user = aws_iam_user.crdb_to_snowflake.name
# }

resource "aws_s3_bucket" "crdb_to_snowflake_demo" {
  bucket = "crdb-to-snowflake-cdc-demo"
}

data "aws_iam_policy_document" "queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:*:*:crdb-to-snowflake-notification-queue"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.crdb_to_snowflake_demo.arn]
    }
  }
}

resource "aws_sqs_queue" "queue" {
  # note: needs to be this particular name, to match the queue used internally in LocalStack Snowflake
  name   = "sf-snowpipe-test"
  policy = data.aws_iam_policy_document.queue.json
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.crdb_to_snowflake_demo.id

  queue {
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
  }
}
