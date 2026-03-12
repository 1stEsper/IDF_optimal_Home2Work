{{ config(materialized='view') }}

SELECT

    string_field_0 as agency_id,
    string_field_1 as agency_name,
    string_field_2 as agency_url,
    string_field_3 as agency_timezone,
    string_field_4 as agency_lang,
    CURRENT_DATE() AS snapshot_date
    
FROM {{ source('bronze_raw', 'agency') }}
WHERE string_field_0 IS NOT NULL