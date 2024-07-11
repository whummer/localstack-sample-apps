#!/bin/bash

# Simple sample app that illustrates creating a Redshift
# cluster in LocalStack, and running SQL commands against it.

RS_CLUSTER_IDENTIFIER="test"
RS_SCHEMA_NAME="public"
RS_DATABASE_NAME="db1"
RS_TABLE_NAME="sales"
RS_USERNAME="test"
RS_PASSWORD="test"

# create cluster
awslocal redshift create-cluster \
      --cluster-identifier $RS_CLUSTER_IDENTIFIER \
      --db-name $RS_DATABASE_NAME \
      --master-username $RS_USERNAME \
      --master-user-password $RS_PASSWORD \
      --node-type n1

RS_URL=$(awslocal redshift describe-clusters \
      --cluster-identifier $RS_CLUSTER_IDENTIFIER | jq -r '(.Clusters[0].Endpoint.Address) + ":" + (.Clusters[0].Endpoint.Port|tostring)')
echo $RS_URL
RS_PORT=$(awslocal redshift describe-clusters \
      --cluster-identifier $RS_CLUSTER_IDENTIFIER | jq -r '(.Clusters[0].Endpoint.Port)')
echo $RS_PORT

# create table
awslocal redshift-data execute-statement \
      --cluster-identifier $RS_CLUSTER_IDENTIFIER \
      --database $RS_DATABASE_NAME \
      --sql "create table $RS_TABLE_NAME(id int, name text)"

# insert data into table
awslocal redshift-data execute-statement \
      --cluster-identifier $RS_CLUSTER_IDENTIFIER \
      --database $RS_DATABASE_NAME \
      --sql "insert into $RS_TABLE_NAME(id, name) VALUES (1, 'test entry')"

# Use psql to connect to the instance...
echo "To connect to the Redshift instance:"
echo "psql --host localhost --port $RS_PORT --user $RS_USERNAME $RS_DATABASE_NAME"

echo "Enter password '$RS_PASSWORD' in the prompt below:"
echo "SELECT * FROM $RS_TABLE_NAME" | psql --host localhost --port $RS_PORT --user $RS_USERNAME $RS_DATABASE_NAME
