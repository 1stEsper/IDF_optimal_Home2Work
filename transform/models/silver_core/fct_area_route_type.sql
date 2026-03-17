{{ config(
    materialized='table', 
    cluster_by=['commune_code']
) }}

WITH area_stop_base AS (
    SELECT
        a.commune_code,
        s.stop_id
    FROM {{ ref('core_dim_area_housing') }} a
    JOIN {{ ref('core_dim_stop') }} s
        ON ST_DWITHIN(a.geom_centroid, s.geom, 800)
),

stop_route_mapping AS (
    SELECT DISTINCT
        st.stop_id,
        r.route_id,
        CASE
            WHEN r.route_type IN (1, 2) THEN 'heavy_rail'
            WHEN r.route_type = 0 THEN 'tram'
            WHEN r.route_type = 3 THEN 'bus'
            ELSE 'other'
        END AS route_mode,
        CASE
            WHEN r.route_type = 2 THEN 25
            WHEN r.route_type = 1 THEN 20
            WHEN r.route_type = 0 THEN 10
            ELSE 1
        END AS mode_weight
    FROM {{ ref('stg_gtfs__stop_times') }} st
    JOIN {{ ref('stg_gtfs__trips') }} t ON st.trip_id = t.trip_id
    JOIN {{ ref('stg_gtfs__routes') }} r ON t.route_id = r.route_id
)

SELECT DISTINCT
    asb.commune_code,
    srm.route_id,
    srm.route_mode,
    srm.mode_weight,
    SUM(srm.mode_weight) OVER(PARTITION BY asb.commune_code) AS total_commune_connectivity_score
FROM area_stop_base asb
JOIN stop_route_mapping srm ON asb.stop_id = srm.stop_id