$ReplaceDatabaseName = 'scs_vin'
$TargetInstance = 'SRSSISPROD\SRStage'
$BackupFolder = '\\coexist.local\dfs\DepartmentShares\Apps\FileTransfers\users\svc-ftp-F&I\Incoming_Prod'
$PermissionFolder = 'C:\SQL\SCS\Scripts\Permissions'
$ScriptCreateDate = get-date -Format  "yyyyMMdd_HHmmss"


#Export database permissions to script
    $PermissionScript = $PermissionFolder + '\' + $ReplaceDatabaseName + '_' + $ScriptCreateDate + '.sql'
    Export-DbaUser -SqlInstance $TargetInstance -Database $ReplaceDatabaseName -FilePath $PermissionScript -Verbose

#Get Latest F&I Full backup file for sra_master/scs_vin database
    $filename = Get-ChildItem "\\coexist.local\dfs\DepartmentShares\Apps\FileTransfers\users\svc-ftp-F&I\Incoming_Prod" -File `
    | Where-Object { ($_.Name -like "scs_auto_master*") -and ($_.LastWriteTime -GT (Get-Date).AddDays(-8) ) } `
    | Sort-Object creationtime -Descending | Select-Object -ExpandProperty Name -Last 1 


#Restore Database
    $backupfile = $BackupFolder + '\' + $filename
    $backupfile | Restore-DbaDatabase -SqlInstance $TargetInstance -DatabaseName $ReplaceDatabaseName -WithReplace


#Set database to SIMPLE recovery model
    $SimpleQuery = 'ALTER DATABASE [' + $ReplaceDatabaseName + '] SET RECOVERY SIMPLE WITH NO_WAIT' 
    Invoke-Sqlcmd -ServerInstance $TargetInstance -Database $ReplaceDatabaseName -Query $SimpleQuery

#Restore permissions
    Invoke-Sqlcmd -ServerInstance $TargetInstance -Database $ReplaceDatabaseName -InputFile $PermissionScript
