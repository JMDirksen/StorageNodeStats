$Hosts = "host1.local", "host2.local"
$DeploymentID = ".........."
$KeepDays = 180
$IntervalMinutes = 60

$Limit = $KeepDays * 24 * 60 / $IntervalMinutes

$Stats = @()
$TotalPayout = 0
$TotalExpectedPayout = 0
$Hosts | ForEach-Object {
    $DiskUsed = (Invoke-RestMethod -Uri ("http://{0}:14002/api/sno/" -f $_)).diskSpace.used
    $DiskUsedTB = [Math]::Round([UInt64]$DiskUsed / [Math]::Pow(10, 12), 3)
    $Stats += $DiskUsedTB
    $BandwidthUsed = (Invoke-RestMethod -Uri ("http://{0}:14002/api/sno/estimated-payout" -f $_)).currentMonth.egressBandwidth
    $BandwidthUsedGB = [Math]::Round([UInt64]$BandwidthUsed / [Math]::Pow(10, 9), 3)
    $Stats += $BandwidthUsedGB
    $TotalPayout += (Invoke-RestMethod -Uri ("http://{0}:14002/api/sno/estimated-payout" -f $_)).currentMonth.payout
    $TotalExpectedPayout += (Invoke-RestMethod -Uri ("http://{0}:14002/api/sno/estimated-payout" -f $_)).currentMonthExpectations
}
$TotalPayout = [Math]::Round([UInt64]$TotalPayout / 100, 2)
$TotalExpectedPayout = [Math]::Round([UInt64]$TotalExpectedPayout / 100, 2)
$Stats += $TotalPayout
$Stats += $TotalExpectedPayout

$Stats = (@((Get-Date).ToString("yyyy-MM-dd HH:mm")) + $Stats) -join ";"
$Uri = "https://script.google.com/macros/s/{0}/exec?stats={1}&limit={2}" -f $DeploymentID, $Stats, $Limit
Invoke-WebRequest -Uri $Uri | Out-Null
