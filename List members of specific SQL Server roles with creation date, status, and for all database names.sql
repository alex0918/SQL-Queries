-- List members of specific SQL Server roles with creation date, status, and for all database names
DECLARE @RoleNames TABLE (Name NVARCHAR(128))
INSERT INTO @RoleNames (Name)
VALUES ('sysadmin'), ('public'); -- Add the role names you want to retrieve

DECLARE @DatabaseNames TABLE (Name NVARCHAR(128))
INSERT INTO @DatabaseNames (Name)
SELECT name
FROM sys.databases
WHERE database_id > 4; -- Exclude system databases

DECLARE @Results TABLE (
    DatabaseName NVARCHAR(128),
    ServerRole NVARCHAR(128),
    MemberName NVARCHAR(128),
    RoleCreateDate DATETIME,
    MemberStatus NVARCHAR(50)
)

DECLARE @RoleName NVARCHAR(128)
DECLARE @DatabaseName NVARCHAR(128)

WHILE EXISTS (SELECT 1 FROM @RoleNames)
BEGIN
    SELECT TOP 1 @RoleName = Name FROM @RoleNames

    WHILE EXISTS (SELECT 1 FROM @DatabaseNames)
    BEGIN
        SELECT TOP 1 @DatabaseName = Name FROM @DatabaseNames

        INSERT INTO @Results (DatabaseName, ServerRole, MemberName, RoleCreateDate, MemberStatus)
        SELECT 
            @DatabaseName AS DatabaseName,
            @RoleName AS ServerRole,
            p.name AS MemberName,
            r.create_date AS RoleCreateDate,
            CASE 
                WHEN p.is_disabled = 1 THEN 'Disabled'
                ELSE 'Enabled'
            END AS MemberStatus
        FROM sys.server_role_members srm
        JOIN sys.server_principals r ON srm.role_principal_id = r.principal_id
        JOIN sys.server_principals p ON srm.member_principal_id = p.principal_id
        WHERE r.type = 'R' 
            AND r.name = @RoleName;

        DELETE FROM @DatabaseNames WHERE Name = @DatabaseName;
    END

    DELETE FROM @RoleNames WHERE Name = @RoleName;
END

SELECT * FROM @Results;
