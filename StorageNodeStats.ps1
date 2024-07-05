$ErrorActionPreference = "Stop"

If (-not (Test-Path 'StorageNodeStats.json')) {
    $Settings = @{}
    $Settings.Hosts = @('localhost')
    $Settings.DeploymentID = ""
    $Settings.KeepDays = 60
    $Settings.IntervalMinutes = 180
    $Settings | ConvertTo-Json | Set-Content -Path 'StorageNodeStats.json'
}
$Settings = Get-Content -Path 'StorageNodeStats.json' | ConvertFrom-Json

$Stats = @()
$TotalPayout = 0
$TotalExpectedPayout = 0
$Settings.Hosts | ForEach-Object {
    $sno = Invoke-RestMethod -Uri ("http://{0}:14002/api/sno/" -f $_)
    $estimatedPayout = Invoke-RestMethod -Uri ("http://{0}:14002/api/sno/estimated-payout" -f $_)
    $DiskUsed = $sno.diskSpace.used + $sno.diskSpace.trash
    $DiskUsedTB = [Math]::Round([UInt64]$DiskUsed / [Math]::Pow(10, 12), 3)
    $Stats += $DiskUsedTB
    $BandwidthUsed = $estimatedPayout.currentMonth.egressBandwidth
    $BandwidthUsedGB = [Math]::Round([UInt64]$BandwidthUsed / [Math]::Pow(10, 9), 3)
    $Stats += $BandwidthUsedGB
    $TotalPayout += $estimatedPayout.currentMonth.payout
    $TotalExpectedPayout += $estimatedPayout.currentMonthExpectations
}
$TotalPayout = [Math]::Round([UInt64]$TotalPayout / 100, 2)
$TotalExpectedPayout = [Math]::Round([UInt64]$TotalExpectedPayout / 100, 2)
$Stats += $TotalPayout
$Stats += $TotalExpectedPayout

$Limit = $Settings.KeepDays * 24 * 60 / $Settings.IntervalMinutes
$Stats = (@((Get-Date).ToString("yyyy-MM-dd HH:mm")) + $Stats) -join ";"
$Uri = "https://script.google.com/macros/s/{0}/exec?stats={1}&limit={2}" -f $Settings.DeploymentID, $Stats, $Limit
Invoke-WebRequest -Uri $Uri | Out-Null
