$ErrorActionPreference = "Stop"
Start-Transcript "StorageNodeStats.log"

If (-not (Test-Path 'StorageNodeStats.json')) {
    $Settings = @{}
    $Settings.Hosts = @('localhost')
    $Settings.DeploymentID = ""
    $Settings.KeepDays = 60
    $Settings.IntervalMinutes = 180
    $Settings | ConvertTo-Json | Set-Content -Path 'StorageNodeStats.json'
}
$Settings = Get-Content -Path 'StorageNodeStats.json' | ConvertFrom-Json

$TotalDisk = 0
$TotalDiskUsed = 0
$TotalBandwidthUsed = 0
$TotalPayout = 0
$TotalExpectedPayout = 0
$Settings.Hosts | ForEach-Object {
    $api = "http://$_/api"
    $sno = Invoke-RestMethod -Uri "$api/sno/"
    $estimatedPayout = Invoke-RestMethod -Uri "$api/sno/estimated-payout"
    $TotalDisk += $sno.diskSpace.available
    $TotalDiskUsed += $sno.diskSpace.used + $sno.diskSpace.trash
    $TotalBandwidthUsed += $estimatedPayout.currentMonth.egressBandwidth
    $TotalPayout += $estimatedPayout.currentMonth.payout
    $TotalExpectedPayout += $estimatedPayout.currentMonthExpectations
}
$TotalDisk = [Math]::Round([UInt64]$TotalDisk / [Math]::Pow(10, 12), 3) # TB
$TotalDiskUsed = [Math]::Round([UInt64]$TotalDiskUsed / [Math]::Pow(10, 12), 3) # TB
$TotalBandwidthUsed = [Math]::Round([UInt64]$TotalBandwidthUsed / [Math]::Pow(10, 12), 3) # TB
$TotalPayout = [Math]::Round([UInt64]$TotalPayout / 100, 2)
$TotalExpectedPayout = [Math]::Round([UInt64]$TotalExpectedPayout / 100, 2)
$Stats = @($TotalDisk, $TotalDiskUsed, $TotalBandwidthUsed, $TotalPayout, $TotalExpectedPayout)

$Limit = $Settings.KeepDays * 24 * 60 / $Settings.IntervalMinutes
$Stats = (@((Get-Date).ToString("yyyy-MM-dd HH:mm")) + $Stats) -join ";"
$Uri = "https://script.google.com/macros/s/{0}/exec?stats={1}&limit={2}" -f $Settings.DeploymentID, $Stats, $Limit
Invoke-WebRequest -Uri $Uri | Out-Null
Stop-Transcript
