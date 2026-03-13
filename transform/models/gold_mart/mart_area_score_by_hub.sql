
SELECT
  a.commune_code,
  a.commune_name,
  d.hub_name,
  d.distance_to_hub_km,
  a.housing_score_raw,
  a.mobility_score_raw,
  -- Weighted score: Prioritize being closer to the hub.
  ROUND(
    (a.housing_score_raw * 0.4 + 
     a.mobility_score_raw * 0.3 + 
     (100 - d.distance_to_hub_km * 3) * 0.3),
    1
  ) AS hub_total_score
FROM {{ ref('mart_area_score') }} a
JOIN {{ ref('fct_area_hub_distance') }} d ON a.commune_code = d.commune_code
WHERE d.hub_id = 'HUB_LA_DEFENSE'  -- specific filter hub
ORDER BY hub_total_score DESC
