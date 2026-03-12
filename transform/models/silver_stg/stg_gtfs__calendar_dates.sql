{{ config(materialized='view') }}

SELECT
    service_id,
    SAFE.PARSE_DATE('%Y%m%d', CAST(date AS STRING)) AS date_service, 
    SAFE_CAST(exception_type AS INT64) AS exception_type,
    CURRENT_DATE() AS snapshot_date
    
FROM {{ source('bronze_raw', 'calendar_dates') }}