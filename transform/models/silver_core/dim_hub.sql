{{ config(materialized='table') }}

SELECT
  hub_id,
  hub_name,
  stop_id,
  ST_GEOGPOINT(lon, lat) AS geom
FROM {{ ref('hub_locations') }}
