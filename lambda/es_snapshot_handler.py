import os
from datetime import datetime
from uuid import uuid4

import boto3
import requests
from requests_aws4auth import AWS4Auth


# AWS OpenSearch service identifier
service = "es"

# configuration
host = os.environ.get("DOMAIN_HOST")
region = os.environ.get("DOMAIN_REGION", "us-east-1")
snapshot_repo = os.environ.get("DOMAIN_REPO_NAME", "my-snapshot-repo")
snapshot_name_base = os.environ.get("DOMAIN_SNAPSHOT_NAME", "my-snapshot")


def lambda_handler(event, context):

    print("Elasticsearch backup Lambda")
    print(f"Domain host: {host}")
    print(f"Snapshot name base: {snapshot_name_base}")
    print(f"Snapshot repo: {snapshot_repo}")

    auth = authentication()
    
    register_snapshot_repository(auth)
    take_snapshot(auth)

    return event


def authentication() -> AWS4Auth:
    """Sign requests to AWS OpenSearch with the credentials taken from Lambda function IAM role"""

    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(
        credentials.access_key,
        credentials.secret_key,
        region,
        service,
        session_token=credentials.token,
    )

    return awsauth


def register_snapshot_repository(awsauth: AWS4Auth):
    """Register a new snapshot repository, if already done this function will not do anything"""

    s3_bucket = os.environ.get("DOMAIN_REPO_S3BUCKET")
    role_arn = os.environ.get(
        "DOMAIN_SNAPSHOT_ROLE_ARN", "arn:aws:iam::729306487939:role/SnapshotRole"
    )

    path = f"_snapshot/{snapshot_repo}"
    url = host + path

    payload = {
        "type": "s3",
        "settings": {
            "bucket": s3_bucket, 
            "region": region, 
            "role_arn": role_arn
        }
    }

    headers = {"Content-Type": "application/json"}

    r = requests.put(url, auth=awsauth, json=payload, headers=headers)
    if r.status_code != 200:
        raise Exception(
            f"Cannot register the snapshot repository {snapshot_repo}. Details: {r.text}"
        )
    else:
        print(r.text)


def take_snapshot(awsauth: AWS4Auth):
    """Take a snapshot of the OpenSearch domain by appending a date to the basename given in the environment"""

    name = snapshot_name_base + datetime.today().strftime('%Y_%m_%d-%H_%M_%S')

    path = f"_snapshot/{snapshot_repo}/{name}"
    url = host + path

    r = requests.put(url, auth=awsauth)
    if r.status_code != 200:
        raise Exception(
            f"Cannot take snapshot {name} in repository {snapshot_repo}. Details: {r.text}"
        )
    else:
        print(r.text)


def restore_snapshot(awsauth: AWS4Auth):
    """This function is not invoked by the Lambda but it can be used for restoring previous snapshots"""

    if snapshot_name_base is None:
        raise EnvironmentError("For restoring a snapshot, you must provide a basename for the OpenSearch "
                               "snapshots in the environmental variable DOMAIN_SNAPSHOT_NAME")
    
    name = snapshot_name_base
    path = f"_snapshot/{snapshot_repo}/{name}/_restore"
    url = host + path

    payload = {"indices": "-.kibana*", "include_global_state": False}
    headers = {"Content-Type": "application/json"}

    r = requests.post(url, auth=awsauth, json=payload, headers=headers)
    if r.status_code != 200:
        raise Exception(
            f"Cannot restore snapshot {name} in repository {snapshot_repo}. Details: {r.text}"
        )
    else:
        print(r.text)
