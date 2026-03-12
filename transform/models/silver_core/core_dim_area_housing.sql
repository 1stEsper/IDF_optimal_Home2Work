{{ config(
    materialized='table',
    unique_key='commune_code',
    cluster_by=['commune_code']
) }}

WITH latest_rent AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY commune_code 
               ORDER BY snapshot_date DESC
           ) AS rn
    FROM {{ ref('stg_housing__rent_commune_2025') }}
),

valid_rent AS (
    SELECT *
    FROM latest_rent
    WHERE rn = 1
      AND loyer_pred_m2 IS NOT NULL
      AND nb_obs_commune >= 3  -- filter minimum fiability
),

communes AS (
    SELECT *
    FROM {{ ref('stg_geo__communes') }}
),

joined AS (
    SELECT
        c.commune_code,
        c.commune_name,
        r.epci,
        c.geom_centroid,
        c.lat,
        c.lon,
        
        -- Rent metrics
        r.loyer_pred_m2,
        r.loyer_lower_bound,
        r.loyer_upper_bound,
        r.nb_obs_commune,
        r.r2_adjusted,
        
        -- Business flags
        CASE 
            WHEN r.loyer_pred_m2 < 12 THEN 'low'
            WHEN r.loyer_pred_m2 < 20 THEN 'medium'
            ELSE 'high'
        END AS price_tier,
        
        r.snapshot_date AS rent_snapshot_date,
        c.snapshot_date AS geo_snapshot_date
        
    FROM communes c
    LEFT JOIN valid_rent r ON c.commune_code = r.commune_code
)

SELECT *
FROM joined
