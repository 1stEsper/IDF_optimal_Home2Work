-- models/gold_mart/mart_area_score.sql
{{ config(
    materialized='table',
    cluster_by=['commune_code']
) }}

WITH area_housing AS (
  SELECT
    commune_code,
    commune_name,
    loyer_pred_m2,
    -- Housing score (cheaper = higher score)
    GREATEST(0, 100 - (loyer_pred_m2 - 10) * 5) AS housing_score_raw
  FROM {{ ref('core_dim_area_housing') }}
),

area_mobility AS (
  SELECT
    commune_code,
    n_stops_within_800m,
    min_distance_to_stop_m,
    -- Mobility score (More stops + closer = higher point)
    LEAST(100, n_stops_within_800m * 10) AS mobility_score_raw
  FROM {{ ref('fct_area_mobility') }}
),

final_score AS (
  SELECT
    h.commune_code,
    h.commune_name,
    h.loyer_pred_m2,
    h.housing_score_raw,
    m.n_stops_within_800m,
    m.min_distance_to_stop_m,
    m.mobility_score_raw,
    
    -- Total score = 50% housing + 50% mobility
    ROUND((h.housing_score_raw * 0.5 + m.mobility_score_raw * 0.5), 1) AS total_score
  FROM area_housing h
  LEFT JOIN area_mobility m ON h.commune_code = m.commune_code
), 
ranked_score AS (
    SELECT *, 
        ROW_NUMBER() OVER (ORDER BY total_score DESC) AS score_rank
    FROM final_score
)

SELECT *
FROM ranked_score

