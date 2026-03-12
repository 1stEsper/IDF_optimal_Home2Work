{{ config (
    materialized = 'view'
)
}}

SELECT 
    stop_id, 
    stop_code, 
    stop_name, 
    stop_desc, 
    SAFE_CAST(stop_lat AS FLOAT64) AS stop_lat, 
    SAFE_CAST(stop_lon AS FLOAT64) AS stop_lon,
    ST_GEOGPOINT(
        SAFE_CAST(stop_lon AS FLOAT64),
        SAFE_CAST(stop_lat AS FLOAT64)
    ) AS geom,
    location_type, 
    parent_station,
    CURRENT_DATE() AS snapshot_date
    
FROM {{source('bronze_raw', 'stops')}}
WHERE stop_id IS NOT NULL
