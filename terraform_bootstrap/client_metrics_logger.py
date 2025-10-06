
import json
import boto3
import hashlib
import time
import logging

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    import datetime
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    required_header = [
        "member_id",
        "first_name",
        "last_name",
        "dob",
        "gender",
        "phone",
        "email",
        "zip5",
        "plan_id"
    ]
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        client_id = record.get('userIdentity', {}).get('principalId', 'unknown')
        ingestion_time = record['eventTime']
        # Download the file
        obj = s3.get_object(Bucket=bucket, Key=key)
        file_content = obj['Body'].read().decode('utf-8')
        lines = file_content.splitlines()
        if not lines:
            logger.error(json.dumps({"error": "File is empty", "file_name": key}))
            continue
        header = lines[0].split(',')
        if header != required_header:
            logger.error(json.dumps({
                "error": "Invalid header or column order",
                "expected": required_header,
                "found": header,
                "file_name": key
            }))
            continue
        record_count = len(lines) - 1
        checksum = hashlib.md5(file_content.encode('utf-8')).hexdigest()
        log_data = {
            'client_id': client_id,
            'file_name': key,
            'ingestion_time': ingestion_time,
            'record_count': record_count,
            'checksum': checksum
        }
        logger.info(json.dumps(log_data))

        # Move file to internal bucket after validation
        # Use client name from bucket name
        client_name = bucket
        now = datetime.datetime.utcnow()
        date_path = now.strftime('%Y/%m/%d')
        dest_bucket = 'radiant-graph-input'
        dest_key = f"client/{client_name}/{date_path}/{key.split('/')[-1]}"
        s3.copy_object(
            Bucket=dest_bucket,
            CopySource={'Bucket': bucket, 'Key': key},
            Key=dest_key
        )
        logger.info(json.dumps({
            "action": "moved",
            "source": f"s3://{bucket}/{key}",
            "destination": f"s3://{dest_bucket}/{dest_key}"
        }))
    return {'statusCode': 200, 'body': 'Processed'}
