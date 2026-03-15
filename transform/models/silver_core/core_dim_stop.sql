{{ config(
    materialized='table',
    cluster_by=['stop_id']
) }}

WITH stops AS (
    SELECT *
    FROM {{ ref('stg_gtfs__stops') }}
),

areas AS (
    SELECT *
    FROM {{ ref('core_dim_area_housing') }}
),

enriched_stops AS (
    SELECT
        s.stop_id,
        s.stop_name,
        s.geom,
        s.location_type,
        s.parent_station,
        
        a.commune_code,
        a.commune_name,
        a.loyer_pred_m2,
        a.price_tier,
        
        -- Distance
        ST_DISTANCE(s.geom, a.geom_centroid) AS distance_to_commune_center_m,
        
        s.snapshot_date
        
    FROM stops s
    LEFT JOIN areas a 
        -- Find the nearest commune (radius 1000m)
        ON ST_DWITHIN(s.geom, a.geom_centroid, 1000) 
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY s.stop_id
        ORDER BY a.loyer_pred_m2 ASC, ST_DISTANCE(s.geom, a.geom_centroid) ASC -- Low price is the priority.
    ) = 1
)

SELECT *
FROM enriched_stops
