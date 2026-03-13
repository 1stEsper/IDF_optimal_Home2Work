{{ config(materialized='table') }}

SELECT
  a.commune_code,
  a.commune_name,
  h.hub_id,
  h.hub_name,
  ROUND(ST_DISTANCE(a.geom_centroid, h.geom) / 1000, 2) AS distance_to_hub_km,
  CASE 
    WHEN ST_DISTANCE(a.geom_centroid, h.geom) / 1000 <= 10 THEN 'near'
    WHEN ST_DISTANCE(a.geom_centroid, h.geom) / 1000 <= 30 THEN 'medium'
    ELSE 'far'
  END AS distance_tier
FROM {{ ref('core_dim_area_housing') }} a
CROSS JOIN {{ ref('dim_hub') }} h
