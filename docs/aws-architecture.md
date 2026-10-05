# AWS Production Architecture (diagram only)

How the local solution would run in production. Every local component has a direct managed equivalent, so the SQL
models, cheat rules and report queries move over unchanged.

```mermaid
flowchart LR
  subgraph Game["Game realm"]
    S1[Shards 01-04] -->|events| K[Amazon Kinesis Data Streams]
    PG[(Game state DB<br/>Amazon RDS Postgres)]
  end

  subgraph Ingest["Ingestion"]
    K --> F[Amazon Data Firehose]
    PG -->|daily snapshot of ref + game tables| DMS[AWS DMS]
  end

  subgraph Lake["Data lake on Amazon S3"]
    F --> RAW[(raw / bronze<br/>Parquet, partitioned by received date)]
    DMS --> RAW
    RAW --> STG[(staging / silver<br/>Apache Iceberg tables)]
    STG --> MART[(marts + cheats / gold<br/>Apache Iceberg tables)]
  end

  subgraph Compute["Transform and orchestration"]
    MWAA[Amazon MWAA<br/>Airflow schedule] --> DBT[dbt on Amazon Athena<br/>SQL models from transform/models]
    DBT --> STG
    DBT --> MART
    GLUE[AWS Glue Data Catalog] --- RAW
    GLUE --- STG
    GLUE --- MART
  end

  subgraph Serve["Serving"]
    MART --> ATH[Amazon Athena]
    ATH --> QS[Amazon QuickSight / Power BI<br/>player and economy dashboards]
    MART --> ALERT[Lambda: new high-severity violation]
    ALERT --> SNS[Amazon SNS / Slack<br/>anti-cheat team]
  end

  CW[Amazon CloudWatch<br/>pipeline + data-quality alarms] -.-> MWAA
```

## How the local pieces map

| Local | AWS | Notes |
|---|---|---|
| Postgres snapshot (Docker) | Kinesis Data Streams (events) + RDS (state) | Events stream continuously instead of a one-off snapshot |
| `ingestion/extract.py` | Data Firehose (events), DMS (state tables) | Firehose writes Parquet partitioned by received time, as locally |
| `data/raw` Parquet | S3 raw / bronze | Same layout |
| DuckDB warehouse | S3 + Apache Iceberg, queried by Athena | Iceberg gives table updates and time travel |
| `transform/run.py` + SQL models | dbt (dbt-athena) scheduled by MWAA | The SQL files become dbt models (ADR 0003) |
| `dq.dq_summary`, reconciliation manifest | dbt tests + CloudWatch alarms | Alert when duplicates, gaps or clock skew exceed a threshold |
| `cheats.*` rule engine | dbt models + Lambda alert on new high-severity rows | Anti-cheat team notified within the batch interval |
| `reports/sql` | Athena views behind QuickSight or Power BI | Same queries |

## Production changes compared with the local version

* **Incremental loads:** process new events by received hour instead of rebuilding everything (dbt incremental
  models keyed on `server_event_id`, which also deduplicates late redeliveries).
* **Clock-skew detection is automated:** a data-quality check on `received_at - event_ts` per shard per hour
  raises an alarm and proposes a correction row instead of relying on manual discovery.
* **Lost-event monitoring:** `shard_seq` gaps are tracked per shard per hour; a sudden rise is an alert.
* **Near real time for the worst cheats:** burst damage and item duplication can be detected in the stream
  (Kinesis Data Analytics / Managed Flink) within seconds, while the full rule set runs in batch.
* **Security:** S3 encryption with KMS, Lake Formation permissions per layer, no direct access to raw player data
  for dashboard users.
