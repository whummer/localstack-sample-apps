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
