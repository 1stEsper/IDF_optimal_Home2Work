{{ config(materialized='view') }}

SELECT
    from_stop_id,
    to_stop_id,
    transfer_type,
    SAFE_CAST(min_transfer_time AS INT64) AS min_transfer_time,
    CURRENT_DATE() AS snapshot_date
    
FROM {{ source('bronze_raw', 'transfers') }}