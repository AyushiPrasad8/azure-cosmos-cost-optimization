import logging
import azure.functions as func
from azure.cosmos import CosmosClient
from azure.storage.blob import BlobServiceClient
import gzip, json, datetime, os

def main(mytimer: func.TimerRequest) -> None:
    endpoint = os.environ['COSMOS_ENDPOINT']
    key = os.environ['COSMOS_KEY']
    database = os.environ['COSMOS_DB']
    container = os.environ['COSMOS_CONTAINER']

    blob_conn_str = os.environ['BLOB_CONN']
    blob_container = os.environ['BLOB_CONTAINER']

    client = CosmosClient(endpoint, key)
    db = client.get_database_client(database)
    container = db.get_container_client(container)

    cutoff_date = (datetime.datetime.utcnow() - datetime.timedelta(days=90)).isoformat()
    query = f"SELECT * FROM c WHERE c.date < '{cutoff_date}'"

    archived_records = []
    for item in container.query_items(query=query, enable_cross_partition_query=True):
        archived_records.append(item)
        container.delete_item(item, partition_key=item['partitionKey'])

    if archived_records:
        filename = f"billing_{datetime.datetime.utcnow().isoformat()}.json.gz"
        blob_service_client = BlobServiceClient.from_connection_string(blob_conn_str)
        blob_client = blob_service_client.get_blob_client(container=blob_container, blob=filename)

        json_bytes = json.dumps(archived_records).encode('utf-8')
        compressed = gzip.compress(json_bytes)
        blob_client.upload_blob(compressed)

    logging.info(f"Archived {len(archived_records)} records.")
