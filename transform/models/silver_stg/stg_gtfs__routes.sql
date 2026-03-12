{{ config(materialized='view') }}

SELECT
    route_id,
    agency_id,
    route_short_name,
    route_long_name,
    route_type,
    route_desc,
    route_color,
    route_text_color,
    CURRENT_DATE() AS snapshot_date
    
FROM {{ source('bronze_raw', 'routes') }}
WHERE route_id IS NOT NULL