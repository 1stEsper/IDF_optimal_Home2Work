{{ config(
    materialized='table',
    cluster_by=['hub_id', 'hub_rank']
) }}

WITH area_base AS (
  SELECT
    commune_code,
    commune_name,
    loyer_pred_m2,
    CASE 
      WHEN commune_code LIKE '751%' THEN GREATEST(0, LEAST(100, (33 - loyer_pred_m2) / (33 - 28) * 100))
      ELSE GREATEST(0, LEAST(100, (23 - loyer_pred_m2) / (23 - 17) * 100))
    END AS housing_score
  FROM {{ ref('core_dim_area_housing') }}
),

hub_distance AS (
  SELECT commune_code, hub_id, hub_name, distance_to_hub_km, distance_score
  FROM {{ ref('fct_area_hub_distance') }}
),

scored AS (
  SELECT
    a.commune_code,
    a.commune_name,
    d.hub_id,
    d.hub_name,
    a.loyer_pred_m2,
    a.housing_score,
    d.distance_to_hub_km,
    d.distance_score,
    CASE 
        WHEN d.distance_to_hub_km <= 5 THEN 20 
        WHEN d.distance_to_hub_km <= 10 THEN 15
        WHEN d.distance_to_hub_km <= 15 THEN 10
        ELSE 0 
    END AS location_bonus,
    ROUND((a.housing_score * 0.5 + d.distance_score * 0.5) +
           (CASE 
                WHEN d.distance_to_hub_km <= 5 THEN 20 
                WHEN d.distance_to_hub_km <= 10 THEN 15
                WHEN d.distance_to_hub_km <= 15 THEN 10
                ELSE 0 
            END),1) AS hub_total_score,
    
    ROW_NUMBER() OVER (
      PARTITION BY d.hub_id 
      ORDER BY (a.housing_score * 0.5 + d.distance_score * 0.5) +
           (CASE 
                WHEN d.distance_to_hub_km <= 5 THEN 20 
                WHEN d.distance_to_hub_km <= 10 THEN 15
                WHEN d.distance_to_hub_km <= 15 THEN 10
                ELSE 0 
            END) DESC
    ) AS hub_rank
  FROM area_base a
  JOIN hub_distance d ON a.commune_code = d.commune_code
)

SELECT 
    *,
    CASE 
        WHEN hub_rank = 1 THEN 'Best Value Hub-Location'
        WHEN hub_rank <= 3 THEN 'Top 3 Recommended'
        WHEN hub_rank <= 10 THEN 'Top 10 Potential'
        ELSE 'Others'
    END AS recommendation_label
FROM scored
WHERE hub_rank <= 10
