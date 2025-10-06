# Radiant Graph Data Ingestion Bootstrap

## Overview
Radiant Graph enables secure, compliant ingestion and processing of client CSV files. The process begins when a client uploads a file to their dedicated S3 bucket (created manually or via onboarding procedures, see `s3_client_bucket_creation.tf`).

1. **Client Upload**: The client uploads a CSV file to their bucket (e.g., `var.bucket_name` from `s3_client_bucket_creation.tf`).
2. **Sanity Checks**: Upon upload, the file is immediately evaluated for sanity and metadata checks.
3. **Input Processing Bucket**: If the file passes checks, it is moved to the input processing bucket (`radiant-graph-input` from `s3_raw_input_bucket.tf`).
4. **Databricks Job Trigger**: An S3 event notification triggers a Lambda function, which invokes a Databricks job via API, passing the S3 file location.
5. **Delta Table Ingestion**: All valid records are ingested into a Delta table, ZSTD compressed and partitioned by client name, date, and zip code for optimal performance.

---

## Manual Steps Before Terraform

### Lambda Packaging
For each Lambda function, install required packages and create a deployment zip:

- For `client_metrics_logger.py`:
  ```bash
  pip install boto3 -t .
  zip client_metrics_logger.zip client_metrics_logger.py boto3/*
  ```
- For `trigger_dbx_input_processing.py`:
  ```bash
  pip install requests -t .
  pip install boto3 -t .
  zip trigger_dbx_input_processing.zip trigger_dbx_input_processing.py requests/* boto3/*
  ```

### Lambda Environment Variables
Set the following for Databricks-trigger Lambda:
- `DATABRICKS_INSTANCE`: Your Databricks workspace hostname (e.g., `adb-xxxxxx.XX.azuredatabricks.net`)
- `DATABRICKS_TOKEN`: Databricks personal access token
- `DATABRICKS_JOB_ID`: Job ID of the Databricks notebook to run

---

## Terraform Steps to Bootstrap

1. Run `terraform init` in the `terraform_bootstrap` directory.
2. Run `terraform apply` to provision all resources:
   - Client S3 bucket and IAM role/policy
   - Input processing S3 bucket
   - Lambda functions and IAM roles
   - S3 event notification to Lambda
   - Databricks job trigger integration
3. After running `terraform apply`, copy the value of `sns_failure_notification_arn` from the outputs and set it as the `SNS_TOPIC_ARN` environment variable in your Databricks notebook (`process_input_files_notebook.ipynb`). This enables automatic email notifications on processing failures.

---

## Security & Compliance
- All buckets are encrypted (AES256), versioned, and tagged for HIPAA/SOC2 compliance.
- IAM policies restrict access to only authorized client and internal roles.
- All data movement uses secure transport (HTTPS).
- Lambda roles are scoped to only necessary permissions.

---

## Data Compliance & De-Identification

All valid records ingested into the Delta table are transformed for compliance purposes:
- Personally identifiable information (PII) is de-identified or masked:
  - `member_id` is hashed (SHA-256)
  - `first_name` and `last_name` are redacted
  - `dob` is truncated to birth year
  - `phone` and `email` are masked
  - `zip5` is truncated to zip3
- Only de-identified data is stored in the Delta table for analytics and downstream processing.
- These transformations ensure HIPAA and SOC2 compliance for all processed records.

---

## Ingestion Error Rate from CloudWatch Logs

The ingestion error rate is calculated using CloudWatch logs generated during file processing. Each log entry records:
- `Failed Records`: Number of invalid records written to the failed records CSV
- `Total Records Processed`: Total number of records processed from the input file

Example log entry:
```
Client: <client>, Date: <date>, Failed Records: <failed_count>, Total Records Processed: <total_records>
```

To compute the error rate for each file/client/date:
```
ingestion_error_rate = failed_count / total_records
```

You can automate this by:
- Creating a CloudWatch Metric Filter to extract these values
- Using CloudWatch Insights or exporting logs to Athena/S3 for SQL-based aggregation

This provides error rate visibility for each ingestion event as recorded in CloudWatch.

---

## Additional Notes
- The client bucket is created manually or via onboarding (see `s3_client_bucket_creation.tf`).
- Only your AWS account has full access; clients have write-only access.
- The Databricks notebook logic is in `process_input_files_notebook.ipynb`.
- Update Lambda zip files if code changes before re-deploying.
