@echo off
REM Run SQL Server stored procedure to refresh views and log
sqlcmd -S ALEXANDER -d CryptoDB -E -Q "EXEC sp_refresh_crypto_views"