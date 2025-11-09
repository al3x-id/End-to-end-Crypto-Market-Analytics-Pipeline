DROP DATABASE IF EXISTS CryptoDB;
GO

CREATE DATABASE CryptoDB;
GO

USE CryptoDB;
GO

CREATE TABLE CryptoData (
    id INT PRIMARY KEY,
    name NVARCHAR(100),
    symbol NVARCHAR(50),
    price DECIMAL (38,10),
    volume_24h DECIMAL (38,10),
    percent_change_24h DECIMAL (18,8),
    market_cap DECIMAL (38,10),
    last_updated DATETIME,
    price_change_category NVARCHAR(10)
);




SELECT * FROM CryptoData;
