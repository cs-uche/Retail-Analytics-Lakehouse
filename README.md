# Grocery Retail & Loyalty Lakehouse

> **Status:** In progress — environment setup and initial data engineering work.

A Databricks and Delta Lake portfolio project that transforms grocery loyalty data into a medallion lakehouse, with incremental ingestion, historically accurate dimensional models, analytics-ready sales tables, and an eventual household feature mart.

## Project goals

- Ingest grocery transactions, product master data, and household demographics.
- Build **Bronze → Silver → Gold** Delta tables with PySpark and SQL.
- Simulate **change data capture (CDC)** for product/household changes and transaction corrections; the historical source files are not themselves CDC logs.
- Implement **SCD Type 2** dimensions and time-aware fact-to-dimension joins.
- Validate data quality, replay safety, and reconciliation between source and target.
- Orchestrate Databricks jobs and introduce CI/CD after the core pipeline works.

This is an implementation roadmap, **not a claim that these features are already complete**.

## Dataset

We plan to use [dunnhumby — The Complete Journey](https://www.dunnhumby.com/source-files/), a grocery loyalty transaction dataset. The original CSV release and the prepared `completejourney` R package contain *different* transaction counts and schemas; select one release and document its exact files before enforcing row-count assertions.

- [Original source files](https://www.dunnhumby.com/source-files/)
- [Prepared R-package dataset](https://bradleyboehmke.github.io/completejourney/)

Do not commit raw dataset files, credentials, or personal access tokens. Store source data in the Databricks landing Volume.

## Intended architecture

```text
External grocery CSV files + deterministic synthetic CDC events
                        |
                        v
        retail_analytics.landing.raw (Volume)
                        |
                Auto Loader / Spark
                        v
         retail_analytics.bronze (Delta)
                        |
         Cleaning, deduplication, CDC,
         SCD2 history, quality checks
                        v
         retail_analytics.silver (Delta)
                        |
         Facts, dimensions, aggregates
                        v
          retail_analytics.gold (Delta)
                        |
            SQL / BI / ML features
```

Unity Catalog layout:

```text
retail_analytics                  # Project catalog
├── landing
│   └── raw                       # Managed Volume for files
├── bronze                        # Raw Delta tables
├── silver                        # Cleaned / historically tracked tables
└── gold                          # Analytical models
```

Landing files will be accessible inside Databricks at `/Volumes/retail_analytics/landing/raw/`.

## Development setup

### Requirements

- Python 3.11 or 3.12 and `pip`
- Git
- A Databricks workspace (Free Edition is sufficient for initial work)
- **Modern Databricks CLI** (standalone executable, not the legacy Python package `databricks-cli`)

> **Shell distinction:** Git Bash on Windows is not Linux. `uname -s` usually reports `MINGW...` in Git Bash and `Linux` inside WSL2/Ubuntu. Follow the appropriate section below. You do **not** need to switch to WSL merely to use the Databricks CLI.

### Option A — Native Linux / Ubuntu / WSL2

Install the modern Databricks CLI in a Linux terminal:

```bash
sudo apt update
sudo apt install -y curl unzip

# Inspect the installer before running it, if desired:
# curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh

curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sudo sh
databricks version
```

The installer normally places the executable at `/usr/local/bin/databricks`.

Create an independent **Linux** virtual environment and install the pinned Python dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements-lock.txt
```

**Note:** A `.venv` created under Windows (with `Scripts/`) cannot be reused inside Linux (which uses `bin/`). Recreate it inside WSL if you switch environments. The `requirements-lock.txt` file is a pip freeze snapshot; a Windows-generated lock may need adjustments for Linux-specific packages.

### Option B — Windows with Git Bash (existing local setup)

**Recommended if you already have a functioning Windows `.venv`.** Install the **Windows** Databricks CLI in PowerShell:

```powershell
winget install --id Databricks.DatabricksCLI -e
```

Restart Git Bash to refresh `PATH`, then verify:

```bash
databricks version
source .venv/Scripts/activate
python -m pip install -r requirements-lock.txt
```

The Windows CLI works from Git Bash because Git Bash can run Windows executables. The Linux CLI binary does **not** run directly in Git Bash.

### Python dependencies and reproducibility

Python dependencies are defined in `pyproject.toml`. For the current pip workflow:

```bash
# Run in an active project virtual environment:
python -m pip install -e ".[dev]"

# Refresh the snapshot after deliberately changing dependencies:
python -m pip freeze --exclude-editable > requirements-lock.txt

# Verify:
python -m pytest --version
python -m ruff --version
```

Commit `pyproject.toml` and `requirements-lock.txt`; do **not** commit the `.venv/` directory. The modern Databricks CLI is a separate **system tool**, so it does not belong in pip requirements. For stricter platform-independent reproducibility later, generate OS-specific lock files or adopt a dedicated lock workflow.

### Databricks authentication

Copy your Databricks workspace **base URL** from the browser (for example `https://dbc-xxxx.cloud.databricks.com`). Authenticate **from the same machine or OS environment where you installed the CLI**:

```bash
databricks auth login --host https://YOUR-WORKSPACE-URL --profile retail-dev
databricks auth profiles
databricks current-user me --profile retail-dev
databricks catalogs list --profile retail-dev
```

If OAuth fails, confirm you are using a fresh sign-in URL and that the CLI can receive the localhost callback. Local Windows CLI authentication avoids the extra GitHub Codespaces forwarded-port layer. Never commit `~/.databrickscfg`, OAuth tokens, PATs, or secrets.

### Unity Catalog initialization

In Databricks **SQL Editor**, run:

```sql
CREATE CATALOG IF NOT EXISTS retail_analytics;

CREATE SCHEMA IF NOT EXISTS retail_analytics.landing;
CREATE SCHEMA IF NOT EXISTS retail_analytics.bronze;
CREATE SCHEMA IF NOT EXISTS retail_analytics.silver;
CREATE SCHEMA IF NOT EXISTS retail_analytics.gold;

CREATE VOLUME IF NOT EXISTS retail_analytics.landing.raw;

SHOW SCHEMAS IN retail_analytics;
SHOW VOLUMES IN retail_analytics.landing;
```

## Implementation roadmap

- [ ] Milestone 0 — Confirm local Python environment, Databricks CLI login, and Unity Catalog structure.
- [ ] Milestone 1 — Download and profile source data; build deterministic daily source feeds.
- [ ] Milestone 2 — Ingest Bronze Delta tables; build minimal Silver and Gold sales models with reconciliation.
- [ ] Milestone 3 — Add CDC handling, product/household SCD2 history, idempotency and recovery tests.
- [ ] Milestone 4 — Build loyalty/campaign analytics, household features, CI/CD and a runbook.
- [ ] Milestone 5 — Benchmark performance and document verifiable results.

## References

- [Install or update the modern Databricks CLI](https://docs.databricks.com/aws/en/dev-tools/cli/install)
- [Databricks CLI authentication](https://docs.databricks.com/aws/en/dev-tools/cli/authentication)
- [The Complete Journey](https://www.dunnhumby.com/source-files/)
