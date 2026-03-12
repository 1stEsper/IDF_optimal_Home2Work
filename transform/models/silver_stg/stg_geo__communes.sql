{{ config(
    materialized='view', 
    partition_by={'field': 'snapshot_date'}
)}}

SELECT
    code_officiel_commune AS commune_code,
    nom_officiel_commune AS commune_name,
    -- code_officiel_département AS dept_code,
    -- nom_officiel_département AS dept_name,
    SAFE_CAST(SPLIT(geo_point, ",")[OFFSET(0)] AS FLOAT64) AS lat,
    SAFE_CAST(SPLIT(geo_point, ",")[OFFSET(1)] AS FLOAT64) AS lon,
    ST_GEOGPOINT(
        SAFE_CAST(TRIM(SPLIT(geo_point, ",")[OFFSET(1)]) AS FLOAT64), -- Lon
        SAFE_CAST(TRIM(SPLIT(geo_point, ",")[OFFSET(0)]) AS FLOAT64)  -- Lat
    ) AS geom_centroid,
    code_officiel_epci AS epci_code,
    nom_officiel_epci AS epci_name,
    
    -- année AS year,
    siren,
    CURRENT_DATE() AS snapshot_date
    
FROM {{ source('bronze_raw', 'communes') }}
WHERE code_officiel_commune IS NOT NULL

