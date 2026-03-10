import os
import pandas as pd
from google.cloud import bigquery
from google.cloud import storage
import re

SERVICE_ACCOUNT_JSON = "../credentials/idf-analysis-0a1db53d06ba.json"
BUCKET_NAME = "idf-analysis-data-lake"

client = bigquery.Client.from_service_account_json(SERVICE_ACCOUNT_JSON)
storage_client = storage.Client.from_service_account_json(SERVICE_ACCOUNT_JSON)

def get_real_sample_uri(gcs_path):
    prefix = gcs_path.split('*')[0]
    blobs = storage_client.list_blobs(BUCKET_NAME, prefix=prefix)
    
    for blob in blobs:
        if blob.name.endswith('.csv') or blob.name.endswith('.txt'):
            return f"gs://{BUCKET_NAME}/{blob.name}"
    return None

def clean_column_name(name):
    name = re.sub(r'^[^\w]+', '', name)
    name = re.sub(r'[\s\.\-]+', '_', name)
    return name.lower()

def get_csv_schema_as_string(sample_uri, delimiter=';'): 
    if not sample_uri: return None
    storage_options = {"token": SERVICE_ACCOUNT_JSON}
    encodings_to_try = ['utf-8-sig', 'iso-8859-1'] 
    
    for enc in encodings_to_try:
        try:
            df = pd.read_csv(
                sample_uri, 
                sep=delimiter, 
                nrows=0, 
                storage_options=storage_options, 
                encoding=enc
            )
            cleaned_columns = [clean_column_name(col) for col in df.columns]
            print(f"--- Đã trích xuất {len(cleaned_columns)} cột (Dùng encoding: {enc}) từ: {sample_uri}")
            
            return [bigquery.SchemaField(name, "STRING") for name in cleaned_columns], enc
        except (UnicodeDecodeError, Exception):
            continue 
            
    return None, None
def ingest_to_bronze(dataset_id, table_id, gcs_path):
    table_ref = client.dataset(dataset_id).table(table_id)
    gcs_uri = f"gs://{BUCKET_NAME}/{gcs_path}"

    is_csv = gcs_path.endswith('.csv') or '/*.csv' in gcs_path

    if is_csv: 
        sample_uri = get_real_sample_uri(gcs_path)
        schema, success_encoding = get_csv_schema_as_string(sample_uri)
        
        if not schema:
            print(f"Error {table_id} cant get schema.")
            return
        if success_encoding == "iso-8859-1":
            encoding_config = {"encoding": "ISO-8859-1"}

        job_config = bigquery.LoadJobConfig(
            schema=schema, 
            autodetect=False, 
            field_delimiter=";",
            skip_leading_rows=1,
            source_format=bigquery.SourceFormat.CSV,
            write_disposition="WRITE_TRUNCATE",

        )
    else: 
        job_config = bigquery.LoadJobConfig(
            autodetect=True,
            source_format=bigquery.SourceFormat.CSV,
            field_delimiter=",",
            skip_leading_rows=1,
            write_disposition="WRITE_TRUNCATE",
            column_name_character_map="V2"
        )

    try: 
        load_job = client.load_table_from_uri(gcs_uri, table_ref, job_config=job_config)
        load_job.result()
        print(f"Success: {gcs_uri} -> {dataset_id}.{table_id}")
    except Exception as e: 
        print(f"An error occurred while loading {table_id}: {e}")

ingest_to_bronze("geo_raw", "communes", "commune_idf/*.csv")
ingest_to_bronze("housing_raw", "rent_commune_2025", "loyer/*.csv")

gtfs_files = ['stops', 'routes', 'trips', 'stop_times', 'calendar', 'calendar_dates', 'agency', 'transfers']
for f in gtfs_files: 
    ingest_to_bronze('idfm_raw', f, f"IDFM-gtfs/{f}.txt")