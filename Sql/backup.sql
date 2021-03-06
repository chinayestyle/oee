USE [oee]
GO
/****** Object:  StoredProcedure [dbo].[BackupDatabases]    Script Date: 03/30/2009 17:57:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[BackupDatabases]
(
	@BackupDir varchar(400),
	@DatabaseName sysname = null,
	@BackupType int = 0 -- 0=Full, 1=Differential, 2=Log
)
AS
 
-- -- Begin Test Code
-- DECLARE @BackupDir varchar(400)
-- SET @BackupDir = 'D:\SQLBackups\Daily\'
-- -- End Test Code
 
-- Create worker table
DECLARE @DBNames TABLE
(
	RowID int IDENTITY PRIMARY KEY,
	DBName varchar(500)
)
 
-- Grab the Database Names from master DB
INSERT INTO @DBNames (DBName)
SELECT Name FROM master.sys.databases
WHERE name = @DatabaseName
   OR @DatabaseName IS NULL
ORDER BY Name
 
-- The below databases are not valid to backup
IF @BackupType = 0
BEGIN
	DELETE @DBNames WHERE DBName IN ('tempdb', 'NorthWind', 'pubs')
END
ELSE IF @BackupType = 1
BEGIN
	DELETE @DBNames WHERE DBName IN ('tempdb', 'NorthWind', 'pubs', 'master')
END
ELSE IF @BackupType = 2
BEGIN
	DELETE @DBNames WHERE DBName IN ('tempdb', 'NorthWind', 'pubs', 'master', 'msdb', 'model')
END
 
IF (@BackupType < 0 OR @BackupType > 2)
	OR NOT EXISTS (SELECT 1 FROM @DBNames)
BEGIN
	RETURN;
END
 
 
-- Declare Session Variables
DECLARE @Now datetime
DECLARE @TodayStr varchar(20)
DECLARE @BackupName varchar(100)
DECLARE @BackupFile varchar(100)
DECLARE @DBName varchar(300)
DECLARE @LogFileName varchar(300)
DECLARE @SQL varchar(2000)
DECLARE @Loopvar int
 
-- Begin looping over Databases in the Work Table
SELECT @Loopvar = min(rowID)
FROM @DBNames
 
WHILE @Loopvar IS NOT NULL
BEGIN
 
-- Database Names have to have [dbname] format since some names have a - or _ in the name
SET @DBName = '['+(SELECT DBName FROM @DBNames WHERE RowID = @LoopVar)+']'
 
--  Set the current date and time
SET @Now = getdate()
 
-- Create backup file date and time in DOS format yyyy_hhmmss
Set @TodayStr = convert(varchar, @Now, 112)+ '_'+replace(convert(varchar, @Now, 108), ':', '')
 
-- Create a variable holding the total path\filename.ext for the log backup
Set @BackupFile = @BackupDir+REPLACE(REPLACE(@DBName, '[',''), ']','')+'-'+ @TodayStr + '-FULL.BAK'
 
-- Provide the backup a SQL name and name in media
Set @BackupName = REPLACE(REPLACE(@DBName, '[',''), ']','')+' full backup for ' + @TodayStr
 
-- Generate the Dynamic SQL script variable to be executed
IF @BackupType = 0
BEGIN
	SET @SQL = 'BACKUP DATABASE ' + @DBName + ' TO DISK = ''' + @BackupFile + ''' WITH INIT, NAME = ''' +@BackupName+''', NOSKIP, NOFORMAT'
END
ELSE IF @BackupType = 1
BEGIN
	SET @SQL = 'BACKUP DATABASE ' + @DBName + ' TO DISK = ''' + @BackupFile + ''' WITH DIFFERENTIAL, INIT, NAME = ''' +@BackupName+''', NOSKIP, NOFORMAT'
END
ELSE IF @BackupType = 2
BEGIN
	SET @SQL = 'BACKUP LOG ' + @DBName + ' TO DISK = ''' + @BackupFile + ''' WITH INIT, NAME = ''' +@BackupName+''' , NOSKIP, NOFORMAT'
END
 
-- Execute the SQL Command 
EXEC(@SQL)
 
-- Goto the Next Database
SELECT @Loopvar = min(rowID)
FROM @DBNames
WHERE RowID > @LoopVar
END
