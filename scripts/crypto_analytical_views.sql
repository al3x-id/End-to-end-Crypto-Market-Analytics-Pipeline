USE CryptoDB;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'view_refresh_log')
BEGIN
    CREATE TABLE view_refresh_log (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        ProcedureName NVARCHAR(100),
        RunDateTime DATETIME DEFAULT GETDATE(),
        Status NVARCHAR(20),
        Message NVARCHAR(MAX) NULL
    );
END

GO

CREATE OR ALTER PROCEDURE sp_refresh_crypto_views AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @startTime DATETIME = GETDATE();

    BEGIN TRY

    PRINT 'Refreshing Crypto Analytics Views...';

    -- Which cryptocurrency has shown the highest volatility in the last 30 days?
    EXEC('
    CREATE OR ALTER VIEW vw_crypto_volatility AS
    SELECT TOP 100 PERCENT
        name,
        symbol,
        ROUND(STDEV(price), 4) AS price_std_dev,
        ROUND(AVG(price), 4) AS avg_price,
        (STDEV(price) / NULLIF(AVG(price), 0)) * 100 AS volatility
    FROM CryptoData
    WHERE last_updated >= DATEADD(DAY, -30, GETDATE())
    GROUP BY name, symbol
    ORDER BY volatility DESC;
    ');
    PRINT 'View vw_crypto_volatility refreshed.';


    -- What is the average daily trading volume trend by market cap tier?
    EXEC('
    CREATE OR ALTER VIEW vw_volume_by_tier AS
    SELECT 
        CASE
            WHEN market_cap >= 10000000000 THEN ''High MCap''
            WHEN market_cap BETWEEN 1000000000 AND 9999999999 THEN ''Mid MCap''
            ELSE ''Low MCap''
        END AS market_tier,
        CAST(AVG(volume_24h) AS BIGINT) AS avg_daily_volume
    FROM CryptoData
    GROUP BY 
        CASE 
            WHEN market_cap >= 10000000000 THEN ''High MCap''
            WHEN market_cap BETWEEN 1000000000 AND 9999999999 THEN ''Mid MCap''
            ELSE ''Low MCap''
        END;
    ');
    PRINT 'View vw_volume_by_tier refreshed.';

   

    --Identify the top 5 coins with the highest growth rate this week.
    EXEC('
    CREATE OR ALTER VIEW vw_top_growth_week AS
    SELECT TOP 5
        name,
        symbol,
        ROUND(((MAX(price) - MIN(price)) / NULLIF(MIN(price), 0)) * 100, 2) AS weekly_growth
    FROM CryptoData
    WHERE last_updated >= DATEADD(DAY, -7, GETDATE())
    GROUP BY name, symbol
    ORDER BY weekly_growth DESC;
    ');
    PRINT 'View vw_top_growth_week refreshed.';


    -- Overview of all coins (price, market cap, volume)
    EXEC('
    CREATE OR ALTER VIEW vw_crypto_summary AS
    SELECT
        name,
        symbol,
        price,
        market_cap,
        volume_24h,
        percent_change_24h,
        price_change_category,
        last_updated
    FROM
    (
        SELECT 
            *,
            ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY last_updated DESC) AS rn
        FROM CryptoData
    ) AS sub
    WHERE sub.rn = 1;
    ');
    PRINT 'View vw_crypto_summary refreshed.';


    -- Top 10 daily or weekly gainers
    EXEC('
    CREATE OR ALTER VIEW vw_top_performers AS
    SELECT TOP 10
        name,
        symbol,
        price,
        percent_change_24h,
        market_cap,
        volume_24h,
        last_updated
    FROM (
        SELECT 
            *,
            ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY last_updated DESC) AS rn
        FROM CryptoData
    ) AS sub
    WHERE sub.rn = 1
    ORDER BY percent_change_24h DESC;
    ');
    PRINT 'View vw_top_performers refreshed.';

   
    -- Coins with most price fluctuations
    EXEC('
    CREATE OR ALTER VIEW vw_volatility AS
    SELECT
        name,
        symbol,
        MAX(price) - MIN(price) AS price_range,
        STDEV(price) AS price_stddev,
        AVG(price) AS avg_price,
        (STDEV(price) / NULLIF(AVG(price), 0)) * 100 AS volatility_percent
    FROM CryptoData
    GROUP BY name, symbol
    HAVING (STDEV(price) / NULLIF(AVG(price), 0)) * 100 IS NOT NULL;
    ');
    PRINT 'View vw_volatility refreshed.';

    
    -- Top daily gainers
    EXEC('
    CREATE OR ALTER VIEW vw_top_daily_gainers AS
    WITH vw_daily_growth AS (
        SELECT
            name,
            symbol,
            CAST(last_updated AS DATE) AS price_date,
            price AS current_price,
            LAG(price) OVER (PARTITION BY name ORDER BY CAST(last_updated AS DATE)) AS previous_price,
            CASE 
                WHEN LAG(price) OVER (PARTITION BY name ORDER BY CAST(last_updated AS DATE)) IS NULL THEN NULL
                WHEN LAG(price) OVER (PARTITION BY name ORDER BY CAST(last_updated AS DATE)) = 0 THEN NULL
                ELSE 
                    ((price - LAG(price) OVER (PARTITION BY name ORDER BY CAST(last_updated AS DATE))) / 
                     LAG(price) OVER (PARTITION BY name ORDER BY CAST(last_updated AS DATE))) * 100
            END AS daily_growth_percent
        FROM CryptoData
    )
    SELECT 
        price_date,
        name,
        symbol,
        daily_growth_percent
    FROM vw_daily_growth
    WHERE daily_growth_percent IS NOT NULL;
    ');
    PRINT 'View vw_top_daily_gainers refreshed';
   
 PRINT 'All crypto analytics views successfully refreshed.';

 INSERT INTO view_refresh_log (ProcedureName, Status, Message)
        VALUES ('sp_refresh_crypto_views', 'SUCCESS', 'All views refreshed successfully');

    END TRY
    BEGIN CATCH
        -- Capture error details
        INSERT INTO view_refresh_log (ProcedureName, Status, Message)
        VALUES (
            'sp_refresh_crypto_views', 
            'FAILED', 
            ERROR_MESSAGE()
        );
    END CATCH
END;

GO

EXEC sp_refresh_crypto_views;

SELECT * FROM view_refresh_log;