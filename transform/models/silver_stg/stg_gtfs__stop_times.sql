{{ config(materialized='view') }}

SELECT
    trip_id,
    arrival_time,
    departure_time,
    stop_id,
    SAFE_CAST(stop_sequence AS INT64) AS stop_sequence,
    pickup_type,
    drop_off_type,
    CURRENT_DATE() AS snapshot_date
    
FROM {{ source('bronze_raw', 'stop_times') }}
WHERE trip_id IS NOT NULL