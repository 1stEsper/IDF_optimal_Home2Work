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
    CASE WHEN commune_code LIKE '751%' THEN 'CORE' ELSE 'OUTER' END AS market_type

  FROM {{ ref('core_dim_area_housing') }}
),

housing_scored AS (
  SELECT *,
    CASE 
      -- Paris (Core): Price from 27.4€ - 45.5€
      WHEN market_type = 'CORE' THEN 
        GREATEST(0, LEAST(100, (45 - loyer_pred_m2) / (45 - 28) * 100))
      -- Suburban (Outer): FROM 16.7€ - 23.5€
      ELSE 
        GREATEST(0, LEAST(100, (23 - loyer_pred_m2) / (23 - 17) * 100))
    END AS housing_score_raw
  FROM area_housing
),

area_mobility AS (
  SELECT
    commune_code,
    n_stops_within_800m,
    min_distance_to_stop_m,
    -- Mobility score (More stops + closer = higher point)
    LEAST(100, (100 - (min_distance_to_stop_m / 8)) + (n_stops_within_800m * 2)) AS mobility_score_raw
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
  FROM housing_scored h
  LEFT JOIN area_mobility m ON h.commune_code = m.commune_code
), 
ranked_score AS (
    SELECT *, 
        ROW_NUMBER() OVER (ORDER BY total_score DESC) AS score_rank
    FROM final_score
)

SELECT *
FROM ranked_score

