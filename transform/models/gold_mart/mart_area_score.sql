{{ config(
    materialized='table',
    cluster_by=['market_segment', 'commune_code']
) }}

WITH mobility_stats AS (
    -- Reducing Mobility and Determining Infrastructure Quality (Rail vs. Bus)
    SELECT 
        m.commune_code,
        MAX(m.total_commune_connectivity_score) AS total_connectivity,
        MIN(f.min_distance_to_stop_m) AS min_dist,
        -- Check if the commune has Metro, RER, or Train access.
        MAX(CASE WHEN m.route_mode = 'heavy_rail' THEN 1 ELSE 0 END) AS has_rail
    FROM {{ ref('fct_area_route_type') }} m
    LEFT JOIN {{ ref('fct_area_mobility') }} f ON m.commune_code = f.commune_code
    GROUP BY 1
),

housing_base AS (
    -- Retrieve housing data and stratify it
    SELECT
        commune_code,
        commune_name,
        loyer_pred_m2,
        CASE 
            WHEN commune_code LIKE '751%' THEN 'CORE'
            WHEN SUBSTR(commune_code, 1, 2) IN ('92', '93', '94') THEN 'INNER_BELT'
            ELSE 'OUTER_BELT'
        END AS market_segment
    FROM {{ ref('core_dim_area_housing') }}
),

distance_to_center AS (
    -- Using the distance to the center (Châtelet) as a general reference point.
    SELECT 
        commune_code,
        distance_to_hub_km AS dist_to_paris
    FROM {{ ref('fct_area_hub_distance') }}
    WHERE hub_name = 'Châtelet'
),

scoring_logic AS (
    -- Calculate the score components with the weights.
    SELECT
        h.*,
        COALESCE(m.has_rail, 0) AS has_rail,
        -- 1. Housing Score
        CASE 
            WHEN h.market_segment = 'CORE' THEN GREATEST(0, LEAST(100, (45 - h.loyer_pred_m2) / (45 - 28) * 100))
            WHEN h.market_segment = 'INNER_BELT' THEN GREATEST(0, LEAST(100, (28 - h.loyer_pred_m2) / (28 - 20) * 100))
            ELSE GREATEST(0, LEAST(90, (23 - h.loyer_pred_m2) / (23 - 15) * 100)) -- Cap at 90 points for Outer
        END AS adjusted_housing_score,

        -- 2. Mobility Score: A 20-point fine will be imposed if only the bus is present.
        COALESCE(
            ROUND(
                ((GREATEST(0, (100 - (m.min_dist / 8))) * 0.6) + 
                (LEAST(100, m.total_connectivity * 1.2) * 0.4)), 1
            ) - (CASE WHEN m.has_rail = 0 THEN 20 ELSE 0 END), 
        0) AS adjusted_mobility_score,

        -- 3. Accessibility Penalty: The penalty for being too far from the center.
        CASE 
            WHEN d.dist_to_paris > 40 THEN -35  -- Very far
            WHEN d.dist_to_paris > 25 THEN -15  -- far
            ELSE 0 
        END AS distance_penalty
    FROM housing_base h
    LEFT JOIN mobility_stats m ON h.commune_code = m.commune_code
    LEFT JOIN distance_to_center d ON h.commune_code = d.commune_code
)

SELECT 
    commune_code,
    commune_name,
    market_segment,
    loyer_pred_m2,
    ROUND(adjusted_housing_score, 1) AS housing_score,
    ROUND(adjusted_mobility_score, 1) AS mobility_score,
    
    -- FINAL TOTAL SCORE: 45% Housing + 45% Transportation + 10% Rail Bonus + Penalty
    ROUND(
        (adjusted_housing_score * 0.45) + 
        (adjusted_mobility_score * 0.45) + 
        (CASE WHEN has_rail = 1 THEN 10 ELSE 0 END) + 
        distance_penalty, 
    1) AS total_suitability_score,

    DENSE_RANK() OVER(ORDER BY ROUND((adjusted_housing_score * 0.45) + (adjusted_mobility_score * 0.45) + (CASE WHEN has_rail = 1 THEN 10 ELSE 0 END) + distance_penalty, 1) DESC) AS final_rank
FROM scoring_logic