{{ config(
    materialized='view',
    partition_by={'field': 'snapshot_date', 'data_type': 'date'}
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('bronze_raw', 'rent_commune_2025') }}
),

staged AS (
    SELECT
        insee_c AS commune_code,
        libgeo AS commune_name,
        epci,
        dep,
        reg,
        SAFE_CAST(REPLACE(loypredm2, ',', '.') AS FLOAT64) AS loyer_pred_m2,
        SAFE_CAST(REPLACE(lwr_ipm2, ',', '.') AS FLOAT64) AS loyer_lower_bound,
        SAFE_CAST(REPLACE(upr_ipm2, ',', '.') AS FLOAT64) AS loyer_upper_bound,
        typpred,
        SAFE_CAST(nbobs_com AS INT64) AS nb_obs_commune,
        SAFE_CAST(nbobs_mail AS INT64) AS nb_obs_maille,
        SAFE_CAST(REPLACE(r2_adj, ',', '.') AS FLOAT64) AS r2_adjusted,
        CURRENT_DATE() AS snapshot_date
        
    FROM raw
    WHERE insee_c IS NOT NULL
)

SELECT *
FROM staged
