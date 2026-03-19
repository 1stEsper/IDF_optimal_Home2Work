# IDF_optimal_Home2Work
## Data Warehouse Optimizing Residential Choice in Île-de-France 


![Display suitable living communes when working at the Austerlitz Hub](result_images/HeadMap.png)

![Top 20 suitable living communes](result_images/top20.png)

**Portfolio project showcasing modern Data Engineering skills**: multi‑format ingestion, dimensional modeling, geospatial analytics, business scoring, data quality, dashboarding.

## **Business Objective**
Help employees (persona: engineer working at La Défense, Châtelet, Massy…) identify optimal Île-de-France communes balancing **housing cost + public transport accessibility** (travel time + line types: metro/RER/tram/bus).

## **Technical Architecture**
```mermaid
graph TB
    A[GTFS IDFM<br/>Communes INSEE<br/>Rent OLL] --> B[**Bronze Raw**<br/>GCS Raw<br/>Python ingestion]
    B --> C[**Silver_stg**<br/>STRING schema<br/>Cleaning<br/>Type casting<br/>Geocoding]
    C --> D[**Silver_core**<br/>dim_area_housing<br/>dim_stop<br/>dim_hub<br/>fct_mobility]
    D --> E[**Gold_mart**<br/>mart_area_score<br/>mart_area_score_by_hub]
    E --> F[**Looker Studio**<br/>Score map<br/>Top 10 ranking<br/>Hub filters]
    
    style A fill:#f9f,stroke:#333
    style F fill:#bbf,stroke:#333

```

## **Tech Stack**
| Category      | Tools                                  |
| ------------- | -------------------------------------- |
| Cloud         | GCP (GCS, BigQuery, Terraform)         |
| Ingestion     | Python (pandas, gcsfs, auto‑encoding)  |
| Modeling      | dbt (medallion, dims/facts, DQ tests)  |
| Spatial       | BigQuery GIS (ST_DWITHIN, ST_DISTANCE) |
| Visualization | Looker Studio (map, ranking, filters)  |

## **Data Sources**
| Source        | Content                                 | Granularity                 |
| ------------- | --------------------------------------- | --------------------------- |
| IDFM GTFS     | 40k+ stops, routes (metro/RER/tram/bus) | stop_id, route_type         |
| Communes IDF  | 1.3k communes, centroids                | INSEE code, geo_point       |
| Rent OLL 2025 | Median rent/m² per commune              | commune_code, loyer_pred_m2 |

## **Technical Pipeline**
1. Bronze Ingestion (Sources → GCS)

Storing data from various sources, with snapshots being the date of ingest.

2. Silver Storage (GCS → BigQuery)

Auto‑encoding detection, flexible STRING schema


3. Silver Core (dbt SQL)

Use **dbt** to normalize and process data before building the data warehouse.

4.  Gold Mart (business scoring)

Data warehouse, business logic.

5. Data Quality (dbt tests)

- unique: commune_code
- not_null_proportion: at_least=0.95, column_name="loyer_pred_m2"
- expression_is_true: "loyer_pred_m2 >= 0 OR loyer_pred_m2 IS NULL"


## **Interactive Dashboard**

I used **Looker Studio** to visualize the optimal living areas for each transport hub.

**Key Features**:

- Heatmap: Identification of high-score communes around Ile-de-France.

- Hub Filter: Instantly switch between Gare de Lyon, Châtelet, etc.

[Locker Studio Dashboard](https://lookerstudio.google.com/reporting/08b7ae5d-f632-4535-b309-fbdad2e60889)


## **Data Engineering Skills Demonstrated**

| Skill                | Implementation                                                |
| -------------------- | ------------------------------------------------------------- |
| Cloud Infrastructure | Terraform (BigQuery datasets, GCS, IAM)                       |
| Complex Ingestion    | Heterogeneous CSV (encoding detection, sep=";"), GTFS parsing |
| Data Modeling        | Medallion + Kimball (dims/facts), dbt macros                  |
| Spatial Analytics    | BigQuery GIS (800m buffer, distance scoring)                  |
| Data Quality         | dbt schema tests + business rules                             |
| Modern Analytics     | Looker Studio + end‑to‑end SQL                                |


## **Local Setup**
<pre>
# 1. Infrastructure
uv run terraform init && terraform apply

# 2. Bronze ingestion
uv run python3 scripts/GCS_to_BQ.py

# 3. Silver storage
uv run python3 scripts/ingest_to_gcs.py

# 3. dbt pipeline
uv run dbt deps && dbt run && dbt test

# 4. Dashboard
</pre>

## **Resources**
### Dataset: 
- "GTFS IDFM" : https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm

*Description data set* : https://eu.ftp.opendatasoft.com/stif/GTFS/GTFS_source_Netex.pdf

- "Commune polygons" https://data.iledefrance.fr/explore/dataset/communes-france/information/?disjunctive.reg_name&disjunctive.dep_name&disjunctive.arrdep_name&disjunctive.ze2020_name&disjunctive.epci_name&disjunctive.ept_name&disjunctive.com_name&disjunctive.ze2010_name&disjunctive.com_is_mountain_area&disjunctive.bv2022_name&sort=year

- Apartment rental prices by commune (2025) 1-2 pieces: https://www.data.gouv.fr/datasets/carte-des-loyers-indicateurs-de-loyers-dannonce-par-commune-en-2025




Date: 17 March 2026
