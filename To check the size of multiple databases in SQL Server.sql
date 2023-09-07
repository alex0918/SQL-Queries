DECLARE @DatabaseName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);

-- Create a table to store the results
CREATE TABLE #DatabaseSizes (
    DatabaseName NVARCHAR(128),
    LogicalName NVARCHAR(128),
    FileType NVARCHAR(128),
    TotalSizeMB DECIMAL(18, 2),
    AvailableSpaceMB DECIMAL(18, 2),
    UsedSpaceMB DECIMAL(18, 2),
    PercentageUsed DECIMAL(18, 2)
);

-- Cursor to loop through databases
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE state_desc = 'ONLINE' -- You can add more conditions as needed

-- Loop through each database
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'
        USE [' + @DatabaseName + N'];
        INSERT INTO #DatabaseSizes
        SELECT
            DB_NAME(database_id) AS DatabaseName,
            name AS LogicalName,
            type_desc AS FileType,
            (size * 8 / 1024) AS TotalSizeMB,
            ((size * 8 / 1024) - ((FILEPROPERTY(name, ''SpaceUsed'') * 8) / 1024)) AS AvailableSpaceMB,
            (FILEPROPERTY(name, ''SpaceUsed'') * 8 / 1024) AS UsedSpaceMB,
            CAST(((FILEPROPERTY(name, ''SpaceUsed'') * 1.0) / (size * 1.0)) * 100 AS DECIMAL(18, 2)) AS PercentageUsed
        FROM sys.master_files
        WHERE DB_NAME(database_id) = ''' + @DatabaseName + N''';'

    EXEC sp_executesql @SQL;

    FETCH NEXT FROM db_cursor INTO @DatabaseName
END

-- Close and deallocate the cursor
CLOSE db_cursor
DEALLOCATE db_cursor

-- Select the results
SELECT * FROM #DatabaseSizes

-- Clean up: Drop the temporary table
DROP TABLE #DatabaseSizes
