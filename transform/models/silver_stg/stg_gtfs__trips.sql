
{{ config(materialized='view') }}

SELECT
    route_id,
    service_id,
    trip_id,
    trip_headsign,
    direction_id,
    block_id,
    shape_id,
    CURRENT_DATE() AS snapshot_date
    
FROM {{ source('bronze_raw', 'trips') }}
WHERE trip_id IS NOT NULL
