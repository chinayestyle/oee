/*
   7. januar 201320:41:20
   User: 
   Server: mikkel-PC\SQLServer
   Database: oee
   Application: 
*/

/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
EXECUTE sp_rename N'dbo.Production.Machine', N'Tmp_MachineName', 'COLUMN' 
GO
EXECUTE sp_rename N'dbo.Production.Tmp_MachineName', N'MachineName', 'COLUMN' 
GO
ALTER TABLE dbo.Production SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

INSERT INTO [oee].[dbo].[MachineConfiguration]
           ([Version]
           ,[MachineName]
           ,[BaseCost])
     VALUES
           (1,'VK125F',0),
           (1,'CNC 2',0)
GO
