import os
from google.cloud import storage

SERVICE_ACCOUNT_JSON = "../credentials/idf-analysis-0a1db53d06ba.json"
BUCKET_NAME  = "idf-analysis-data-lake"
LOCAL_DATA_PATH = "../data_raw/"

allowed_extentions = [".csv", ".txt"]

idfm_target_files = ['stops.txt', "routes.txt", "trips.txt", "agency.txt", "transfers.txt", "stop_times.txt", "calendar.txt", "calendar_dates.txt"]

def upload_to_gcs():
    client = storage.Client.from_service_account_json(SERVICE_ACCOUNT_JSON)
    bucket = client.get_bucket(BUCKET_NAME)

    for root, dirs, files in os.walk(LOCAL_DATA_PATH):
        folder_name = os.path.basename(root)

        for file in files:
            local_path = os.path.join(root, file)
            remote_path = os.path.relpath(local_path, LOCAL_DATA_PATH)
            
            should_upload = False

            if folder_name in ['commune_idf', 'loyer'] and file.endswith('.csv'):
                should_upload = True
            
            elif folder_name == 'IDFM-gtfs' and file in idfm_target_files:
                should_upload = True

            if should_upload:
                blob = bucket.blob(remote_path)
                blob.upload_from_filename(local_path)
                print(f"Uploaded: {remote_path}")

if __name__ == "__main__":
    upload_to_gcs()