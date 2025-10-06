import json
import boto3
import requests
import os

def lambda_handler(event, context):
    # Extract S3 file path from event
    records = event.get('Records', [])
    for record in records:
        s3_bucket = record['s3']['bucket']['name']
        s3_key = record['s3']['object']['key']
        s3_file_path = f"s3://{s3_bucket}/{s3_key}"

        # Databricks job parameters
        databricks_instance = os.environ['DATABRICKS_INSTANCE']
        databricks_token = os.environ['DATABRICKS_TOKEN']
        job_id = os.environ['DATABRICKS_JOB_ID']

        # Databricks API endpoint
        api_url = f"https://{databricks_instance}/api/2.1/jobs/run-now"
        headers = {
            "Authorization": f"Bearer {databricks_token}",
            "Content-Type": "application/json"
        }
        payload = {
            "job_id": int(job_id),
            "notebook_params": {
                "filepath": s3_file_path
            }
        }
        response = requests.post(api_url, headers=headers, data=json.dumps(payload))
        print(f"Triggered Databricks job for file: {s3_file_path}, response: {response.text}")
    return {"status": "done"}
