# Local setup (Windows + VS Code)

Back to the [README](README.md).

Prerequisites: Docker Desktop (WSL 2 backend, must be running), Python 3.10+, ~12 GB free disk (6 GB image + Parquet output).

Open this folder in VS Code, then in the PowerShell terminal (Ctrl+`):

```powershell
# 1. Start the source snapshot (first pull is ~5 GB)
docker compose up -d
docker ps                               # eternal-realms should be "Up"

# 2. Python environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1            # if blocked: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
pip install -r requirements.txt

# 3. Ingest the snapshot into data/raw (Parquet) - prints a reconciliation line per table
python ingestion\extract.py
```

If port 5432 is already in use on your machine: `$env:PGPORT=5433; docker compose up -d` and keep
`$env:PGPORT=5433` set when running `extract.py`.

Expected output: one `OK` line per table, then `All tables reconciled.` The events table prints
progress every 100k rows and takes the longest (roughly 10 to 30 minutes depending on your machine).
Results land in `data/raw/` (git-ignored) with a reconciliation manifest at `data/raw/_manifest.json`.

Quick check that the database is up, without psql installed:
`docker exec -it eternal-realms psql -U candidate -d eternal_realms -c "\dt intake.*"`

## Build the cleaned warehouse

After the ingestion has finished (`All tables reconciled.`), run:

```powershell
python transform\run.py
```

This builds `data\warehouse\eternal_realms.duckdb` (about 3 minutes): cleaning, data-quality checks, the cheat
rule engine and the star schema. You should see a `built ...` line per step and finally `Done: 40 models`.

## Produce the reports

```powershell
python reports\run_reports.py
```

Every report from the brief is saved as a CSV file in `reports\output\` (a few seconds). What each step does, in plain English: [docs/how-it-works.md](docs/how-it-works.md).
