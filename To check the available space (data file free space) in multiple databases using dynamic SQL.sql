DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @DatabaseName NVARCHAR(128);

-- Create a table to store the results
CREATE TABLE #DatabaseAvailableSpace (
    DatabaseName NVARCHAR(128),
    LogicalDataName NVARCHAR(128),
    TotalDataSizeMB DECIMAL(18, 2),
    UsedDataSpaceMB DECIMAL(18, 2),
    AvailableDataSpaceMB DECIMAL(18, 2),
    PercentageDataUsed DECIMAL(18, 2)
);

-- Cursor to loop through user databases
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE database_id > 4 -- Exclude system databases (IDs 1-4) as well as other exclusions as needed

-- Loop through each database and build dynamic SQL
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = @SQL + '
        USE [' + @DatabaseName + '];
        INSERT INTO #DatabaseAvailableSpace
        SELECT
            DB_NAME(database_id) AS DatabaseName,
            name AS LogicalDataName,
            (size * 8 / 1024) AS TotalDataSizeMB,
            ((size * 8 / 1024) - ((FILEPROPERTY(name, ''SpaceUsed'') * 8) / 1024)) AS AvailableDataSpaceMB,
            (FILEPROPERTY(name, ''SpaceUsed'') * 8 / 1024) AS UsedDataSpaceMB,
            CAST(((FILEPROPERTY(name, ''SpaceUsed'') * 1.0) / (size * 1.0)) * 100 AS DECIMAL(18, 2)) AS PercentageDataUsed
        FROM sys.master_files
        WHERE DB_NAME(database_id) = ''' + @DatabaseName + ''' AND type = 0;';

    FETCH NEXT FROM db_cursor INTO @DatabaseName
END

-- Execute the dynamic SQL
EXEC sp_executesql @SQL;

-- Select the results
SELECT * FROM #DatabaseAvailableSpace;

-- Clean up: Drop the temporary table
DROP TABLE #DatabaseAvailableSpace;

-- Close and deallocate the cursor
CLOSE db_cursor;
DEALLOCATE db_cursor;
