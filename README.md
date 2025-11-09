
# Crypto Market Analytics Pipeline

## Project Overview

This project builds a data analytics pipeline for cryptocurrency market data from raw data loading to business-ready insights.
It demonstrates end-to-end data engineering, SQL analytics, and visualization using:

* **Python (Pandas + SQLAlchemy)** for ETL
* **SQL Server** for storage and analytical views
* **Power BI** for visualization
* **Windows Task Scheduler** for automation and logging

---

## Project Architecture

### 1. **ETL Layer (Python → SQL Server)**

Python script [Crypto_ETL_Pipeline](scripts/Crypto_ETL_Pipeline.ipby) automates:
* API configuration and extraction of data from CoinMarketCap
* Saving the raw data as [crypto_raw](Datasets/crypto_raw.csv)
* Transformation of extracted data (pulling only crucial columns and renaming)
* Reading transformed CSV data ([crypto_transformed](Datasets/crypto_transformed.csv))
* Connecting securely to SQL Server
* Loading transformed data to SQL server
* Checking for duplicates
* Appending only new records
* Logging progress

**Libraries used:**
`requests`, `pandas`, `numpy`, `sqlalchemy`, `logging`, `os`, `traceback`

---

### 2. **SQL Server (Analytics Layer)**

SQL Server hosts analytical views that answer key business questions.

| View                   | Purpose                                                          |
| ---------------------- | ---------------------------------------------------------------- |
| `vw_crypto_volatility` | Tracks cryptocurrencies with the highest 30-day volatility       |
| `vw_volume_by_tier`    | Groups coins by market cap tier and shows average trading volume |
| `vw_top_growth_week`   | Shows top 5 coins with highest growth rate in the past 7 days    |
| `vw_crypto_summary`    | Provides an up-to-date summary of all coins (price, cap, volume) |
| `vw_top_performers`    | Lists top 10 daily or weekly gainers                             |
| `vw_top_daily_gainers` | Calculates daily percentage growth        |
| `vw_volatility`        | Shows coins with the most price fluctuations                     |

---

### 3. **Visualization Layer (Power BI Dashboard)**

Power BI connects directly to SQL Server views to create the [Crypto Metrics Dashboard](Dashboard/CryptoMetrics.pbix), which includes:
* **No. of Coins**
* **Average Market Cap**
* **Average Votality**
* **Top Performer**
* **Top Weekly growth Rate**
* **Volatility Trends**
* **Top Daily Gainers**
* **Trading Volume by Tier**

---

### 4. ** Automation (Windows Task Scheduler)**

To ensure continuous and hands-free operation, the entire ETL pipeline is automated using Windows Task Scheduler.
The task runs the main script at a specified interval, allowing the system to:

* Automatically fetch the latest cryptocurrency data
* Update the SQL Server database with new records

### 5. **🧾 Logging and Monitoring**
The ETL pipeline includes a robust logging system that records every stage of the process from data extraction to transformation and loading into SQL Server.
All logs are automatically saved in [crypto_pipeline](scripts/crypto_pipeline.log) for easy monitoring, debugging, and audit tracking.

Each log entry captures:

* Successful API connections and data loads
* Duplicate handling and skipped entries
* Errors with timestamps and stack traces

This ensures transparency and reliability when maintaining or extending the pipeline.

Also logs are automatically written to SQL Server for each view run.

#### Log Table

```sql
 CREATE TABLE view_refresh_log (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        ProcedureName NVARCHAR(100),
        RunDateTime DATETIME DEFAULT GETDATE(),
        Status NVARCHAR(20),
        Message NVARCHAR(MAX) NULL
);
```

#### Log Procedure

```sql
EXEC sp_refresh_crypto_views;
```

#### View Logs

```sql
SELECT TOP 20 * FROM view_refresh_Log ORDER BY RunDateTime DESC;
```

---

## Business Questions Answered

1. Which cryptocurrency is most volatile in the last 30 days?
2. What is the average daily trading volume by market cap tier?
3. Which coins grew the fastest this week?
4. Who are the top 5 gainers today?
5. How volatile is each coin compared to its average price?
