{{ config(
    materialized='table',
    cluster_by=['commune_code']
) }}

WITH areas AS (
  SELECT commune_code, geom_centroid
  FROM {{ ref('core_dim_area_housing') }}
),

stops AS (
  SELECT stop_id, geom
  FROM {{ ref('core_dim_stop') }}
),

mobility_metrics AS (
  SELECT
    a.commune_code,
    
    -- Number of stops in radius 800m (walking distance)
    COUNTIF(ST_DWITHIN(a.geom_centroid, s.geom, 800)) OVER (
      PARTITION BY a.commune_code
    ) AS n_stops_within_800m,
    
    -- Number of stops in 2km (bus accessible)
    COUNTIF(ST_DWITHIN(a.geom_centroid, s.geom, 2000)) OVER (
      PARTITION BY a.commune_code
    ) AS n_stops_within_2km,
    
    -- Distance to the nearest stop
    MIN(ST_DISTANCE(a.geom_centroid, s.geom)) OVER (
      PARTITION BY a.commune_code
    ) AS min_distance_to_stop_m
    
  FROM areas a
  CROSS JOIN stops s
)

SELECT DISTINCT *
FROM mobility_metrics
