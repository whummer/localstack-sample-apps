#!/bin/bash

tflocal init
rm -f terraform.tfstate*
tflocal apply -auto-approve

snow_sql.sh "CREATE TABLE order_alerts (changefeed_record VARIANT)"

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

snow_sql.sh "
CREATE PIPE cdc_pipe
  AUTO_INGEST = TRUE
  AS
  COPY INTO order_alerts
  FROM @cdc_stage
  FILE_FORMAT = (TYPE = 'JSON')
"

#awslocal s3 mb s3://crdb-to-snowflake-cdc-demo

# add bucket notification, to inform Snowflake about new files on S3
# see https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto-s3#determining-the-correct-option
#awslocal s3api put-bucket-notification-configuration --bucket crdb-to-snowflake-cdc-demo \
#  --notification-configuration '{
#    "QueueConfigurations": [{"Id": "c1", "QueueArn": "arn:aws:sqs:us-east-1:000000000000:sf-snowpipe-test", "Events": ["s3:ObjectCreated:*"]}],
#    "EventBridgeConfiguration": {}
#  }'

awslocal s3 cp data.ndjson s3://crdb-to-snowflake-cdc-demo/

sleep 3
snow_sql.sh "SELECT * FROM order_alerts"

#snow_sql.sh "COPY INTO order_alerts FROM @cdc_stage"
#snow_sql.sh "SELECT * FROM order_alerts"

snow_sql.sh "SHOW PIPES"
