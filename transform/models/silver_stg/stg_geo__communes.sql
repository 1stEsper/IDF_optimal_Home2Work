{{ config(
    materialized='view', 
    partition_by={'field': 'snapshot_date'}
)}}

SELECT
    code_insee AS commune_code,
    commune AS commune_name,
    -- code_officiel_département AS dept_code,
    -- nom_officiel_département AS dept_name,
    SAFE_CAST(SPLIT(geo_point_2d, ",")[OFFSET(0)] AS FLOAT64) AS lat,
    SAFE_CAST(SPLIT(geo_point_2d, ",")[OFFSET(1)] AS FLOAT64) AS lon,
    ST_GEOGPOINT(
        SAFE_CAST(TRIM(SPLIT(geo_point_2d, ",")[OFFSET(1)]) AS FLOAT64), -- Lon
        SAFE_CAST(TRIM(SPLIT(geo_point_2d, ",")[OFFSET(0)]) AS FLOAT64)  -- Lat
    ) AS geom_centroid,

    CURRENT_DATE() AS snapshot_date
    
FROM {{ source('bronze_raw', 'communes') }}
WHERE SUBSTR(code_insee, 1, 2) IN ('75', '77', '78', '91', '92', '93', '94', '95')

