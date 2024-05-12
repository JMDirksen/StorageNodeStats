$Hosts = "host1.local", "host2.local"
$DeploymentID = ".........."
$KeepDays = 180
$IntervalMinutes = 15

$Limit = $KeepDays * 24 * 60 / $IntervalMinutes

$Stats = @()
$Hosts | ForEach-Object {
    $used = (Invoke-RestMethod -Uri ("http://{0}:14002/api/sno/" -f $_)).diskSpace.used
    $usedTB = [Math]::Round([UInt64]$used / [Math]::Pow(10, 12), 3)
    $Stats += $usedTB
}

$Stats = (@((Get-Date).ToString("yyyy-MM-dd HH:mm")) + $Stats) -join ";"
$Uri = "https://script.google.com/macros/s/{0}/exec?stats={1}&limit={2}" -f $DeploymentID, $Stats, $Limit
Invoke-WebRequest -Uri $Uri | Out-Null
