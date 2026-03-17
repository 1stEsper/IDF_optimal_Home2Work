{{ config(
    materialized='table',
    cluster_by=['hub_name', 'hub_rank']
) }}

WITH hub_routes AS (
    -- 1. Identify the routes passing through each main Hub
    SELECT DISTINCT
        hub_name,
        route_id
    FROM {{ ref('fct_area_hub_distance') }} d
    JOIN {{ ref('fct_area_route_type') }} m ON d.commune_code = m.commune_code
),

area_to_hub_connectivity AS (
    -- 2. Check for direct connection: Do the commune and the hub share a common train line?
    SELECT 
        m.commune_code,
        hr.hub_name,
        COUNT(DISTINCT m.route_id) AS n_shared_routes,
        -- If there is at least one shared heavy rail line, reward 20 points.
        MAX(CASE WHEN m.route_mode = 'heavy_rail' THEN 20 ELSE 0 END) AS direct_rail_bonus
    FROM {{ ref('fct_area_route_type') }} m
    JOIN hub_routes hr ON m.route_id = hr.route_id
    GROUP BY 1, 2
),

final_scoring AS (
    SELECT
        g.commune_code,
        g.commune_name,
        d.hub_name,
        g.loyer_pred_m2,
        g.market_segment,
        g.housing_score AS base_housing_score,
        g.mobility_score AS base_mobility_score,
        d.distance_to_hub_km,
        COALESCE(c.direct_rail_bonus, 0) AS direct_rail_bonus,

        -- 3. Calculate the Proximity score to the Hub (The closer, the higher the score, maximum 100 points)
        GREATEST(0, 100 - (d.distance_to_hub_km * 2)) AS hub_proximity_score,

        -- 4. Actual distance penalty (Based on the distance to the specific Hub)
        CASE 
            WHEN d.distance_to_hub_km > 30 THEN -40 -- Too far to commute to work every day.
            WHEN d.distance_to_hub_km > 15 THEN -15 -- ~~~
            ELSE 0 
        END AS local_distance_penalty,

        -- PERSONALIZED FORMULA
        ROUND(
            (g.housing_score * 0.35) +          -- 35% of rent
            (g.mobility_score * 0.35) +         -- 35% of the commune's infrastructure quality.
            (COALESCE(c.direct_rail_bonus, 0)) + -- Direct connection bonus (extremely important)
            (GREATEST(0, 100 - (d.distance_to_hub_km * 2)) * 0.1) + -- 10% Physical Distance
            CASE 
                WHEN d.distance_to_hub_km <= 5 THEN 10 -- Bonus if it's super close.
                WHEN d.distance_to_hub_km > 30 THEN -40 
                WHEN d.distance_to_hub_km > 15 THEN -15 
                ELSE 0 
            END, 1
        ) AS total_hub_suitability_score
    FROM {{ ref('mart_area_score') }} g
    JOIN {{ ref('fct_area_hub_distance') }} d ON g.commune_code = d.commune_code
    LEFT JOIN area_to_hub_connectivity c ON g.commune_code = c.commune_code 
                                        AND d.hub_name = c.hub_name
)

SELECT 
    *,
    ROW_NUMBER() OVER(PARTITION BY hub_name ORDER BY total_hub_suitability_score DESC) AS hub_rank
FROM final_scoring
-- Limit the Top 20 best communes for each Hub
QUALIFY hub_rank <= 20