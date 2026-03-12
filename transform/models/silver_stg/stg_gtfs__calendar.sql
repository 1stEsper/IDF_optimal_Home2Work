
{{ config(materialized='view') }}

SELECT
    service_id,
    SAFE_CAST(monday AS INT64)    AS monday,
    SAFE_CAST(tuesday AS INT64)   AS tuesday,
    SAFE_CAST(wednesday AS INT64) AS wednesday,
    SAFE_CAST(thursday AS INT64)  AS thursday,
    SAFE_CAST(friday AS INT64)    AS friday,
    SAFE_CAST(saturday AS INT64)  AS saturday,
    SAFE_CAST(sunday AS INT64)    AS sunday,
    SAFE.PARSE_DATE('%Y%m%d', CAST(start_date AS STRING)) AS start_date, 
    SAFE.PARSE_DATE('%Y%m%d', CAST(end_date AS STRING)) AS end_date, 
    CURRENT_DATE() AS snapshot_date
    
FROM {{ source('bronze_raw', 'calendar') }}
WHERE service_id IS NOT NULL
