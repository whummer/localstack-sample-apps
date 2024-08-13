#!/bin/bash

# deploy the terraform stack (S3 bucket, SQS queue, bucket notification)
tflocal init
rm -f terraform.tfstate*
tflocal apply -auto-approve

# create order_alerts table in Snowflake
snow_sql.sh "CREATE TABLE order_alerts (changefeed_record VARIANT)"

# create stage connected to our S3 bucket
snow_sql.sh "
CREATE STAGE cdc_stage
  ENDPOINT = 'http://localhost:4566'
  URL='s3compat://crdb-to-snowflake-cdc-demo'
  CREDENTIALS = (
    aws_key_id='local_stack_key_id'
    aws_secret_key='local_stack_secret_key'
  )
  FILE_FORMAT = (
    TYPE = 'JSON'
  )
"

# create Snow pipe to copy data from S3 into the `order_alerts` table
snow_sql.sh "
CREATE PIPE cdc_pipe
  AUTO_INGEST = TRUE
  AS
  COPY INTO order_alerts
  FROM @cdc_stage
  FILE_FORMAT = (TYPE = 'JSON')
"

# copy a file to S3, triggering the pipe execution
awslocal s3 cp data.ndjson s3://crdb-to-snowflake-cdc-demo/

# sleep a bit, then select data from the table
sleep 3
snow_sql.sh "SELECT * FROM order_alerts"
