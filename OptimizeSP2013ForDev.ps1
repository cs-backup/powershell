# FileName: OptimizeSP2013ForDev.ps1
#=============================================
# Created: 5/19/2013
# Author: Cory Peters
# Company: Eastridge
# Web: http://www.corypeters.net http://www.eastridge.net
#=============================================
# Purpose:
# SharePoint 2013 is VERY resource hungry and some of us are stuck with development 
# environments with just 16GB of RAM. In order to actually develop in these conditions 
# we must throttle services and be very careful how we configure our development environments.
# This PowerShell script attempts to simplify the optimization process.
#=============================================

Write-Host -ForegroundColor Yellow "----------------------------------------"
Write-Host -ForegroundColor Yellow "| Optimize SharePoint 2013 Environment |"
Write-Host -ForegroundColor Yellow "|       FOR DEVELOPMENT USE ONLY       |"
Write-Host -ForegroundColor Yellow "----------------------------------------"

Write-Host 
Write-Host -ForegroundColor White "# Running automated optimizations"

# Reduce Search Performance Level
Write-Host 
Write-Host -ForegroundColor White " - Reducing search service performance..."
Set-SPEnterpriseSearchService -PerformanceLevel Reduced
Write-Host -BackgroundColor Black -ForegroundColor Green "Success"

# Cap the CacheCluster CacheSize to 300MB rather than 10% of total RAM (Default)
Write-Host 
Write-Host -ForegroundColor White " - Setting maximum AppFabric cache size to 300MB..."
$instanceName ="SPDistributedCacheService Name=AppFabricCachingService"
$serviceInstance = Get-SPServiceInstance | ? {($_.service.tostring()) -eq $instanceName -and ($_.server.name) -eq $env:computername}
$serviceInstance.Unprovision()
Use-CacheCluster
Set-CacheHostConfig -Hostname localhost -cacheport 22233 -cachesize 300 | Out-Null
$serviceInstance.Provision()
Write-Host -BackgroundColor Black -ForegroundColor Green "Success"

# get the directory of this script file
Write-Host 
Write-Host -ForegroundColor White " - Setting maximum noderunner.exe memory to 50MB..."
$appConfigFile = "C:\Program Files\Microsoft Office Servers\15.0\Search\Runtime\1.0\noderunner.exe.config"
$appConfig = New-Object XML
$appConfig.Load($appConfigFile)
$appConfig.configuration.nodeRunnerSettings.memoryLimitMegabytes = "50"
$appConfig.Save($appConfigFile)
Write-Host -BackgroundColor Black -ForegroundColor Green "Success"

Write-Host
Write-Host -ForegroundColor White " - Setting all user databases to Simple Recovery"
$server = "localhost"
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $server
$SMOserver.Databases | where {$_.IsSystemObject -eq $false} | foreach {$_.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple; $_.Alter()}
Write-Host -BackgroundColor Black -ForegroundColor Green "Success"

Write-Host
Write-Host -ForegroundColor White " - Setting SQL maximum memory to 2500MB"
$SMOserver.Configuration.MaxServerMemory.ConfigValue = 2500
$SMOserver.Configuration.Alter()
Write-Host -BackgroundColor Black -ForegroundColor Green "Success"

Write-Host 
Write-Host -ForegroundColor White "# Scanning for manual optimizations"

Write-Host 
Write-Host -ForegroundColor White " - Checking number of web applications"
$m = Get-SPWebApplication | measure
if ($m.Count -gt 1)
{
	Write-Host -BackgroundColor Black -ForegroundColor Red "($($m.Count)) Web applications were found. Recommend only 1 web application!"
}
else
{
	Write-Host -BackgroundColor Black -ForegroundColor Green "Good"
}
