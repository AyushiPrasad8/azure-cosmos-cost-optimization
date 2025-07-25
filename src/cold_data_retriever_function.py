import logging
import azure.functions as func
import json
import gzip
import os
from azure.storage.blob import BlobServiceClient
from azure.cosmos import CosmosClient, PartitionKey

def main(req: func.HttpRequest) -> func.HttpResponse:
    record_id = req.params.get('id')
    if not record_id:
        return func.HttpResponse("Missing 'id'", status_code=400)

    cosmos_client = CosmosClient(os.environ["COSMOS_ENDPOINT"], os.environ["COSMOS_KEY"])
    db = cosmos_client.get_database_client(os.environ["COSMOS_DB"])
    container = db.get_container_client(os.environ["COSMOS_CONTAINER"])

    try:
        record = container.read_item(record_id, partition_key=record_id)
        return func.HttpResponse(json.dumps(record), mimetype="application/json")
    except:
        pass

    blob_service_client = BlobServiceClient.from_connection_string(os.environ["BLOB_CONN"])
    container_client = blob_service_client.get_container_client(os.environ["BLOB_CONTAINER"])
    blobs = container_client.list_blobs()

    for blob in blobs:
        blob_data = container_client.download_blob(blob).readall()
        decompressed = gzip.decompress(blob_data).decode("utf-8")
        records = json.loads(decompressed)
        for rec in records:
            if rec["id"] == record_id:
                container.upsert_item(rec)
                return func.HttpResponse(json.dumps(rec), mimetype="application/json")

    return func.HttpResponse("Record not found", status_code=404)
