$ErrorActionPreference = "Stop"

function Main {
    try {
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
            $result = Invoke-Api $_
            $TotalDisk += $result.diskSpace.available
            $TotalDiskUsed += $result.diskSpace.used + $result.diskSpace.trash
            $TotalBandwidthUsed += $result.estimatedPayout.currentMonth.egressBandwidth
            $TotalPayout += $result.estimatedPayout.currentMonth.payout
            $TotalExpectedPayout += $result.estimatedPayout.currentMonthExpectations        
        }

        $Stats = @(
            (ConvertTo-Terabytes -Bytes $TotalDisk),
            (ConvertTo-Terabytes -Bytes $TotalDiskUsed),
            (ConvertTo-Terabytes -Bytes $TotalBandwidthUsed),
            (ConvertTo-Dollar -DollarCents $TotalPayout),
            (ConvertTo-Dollar -DollarCents $TotalExpectedPayout)
        )

        $Limit = $Settings.KeepDays * 24 * 60 / $Settings.IntervalMinutes
        $Stats = (@((Get-Date).ToString("yyyy-MM-dd HH:mm")) + $Stats) -join ";"
        $Uri = "https://script.google.com/macros/s/{0}/exec?stats={1}&limit={2}" -f $Settings.DeploymentID, $Stats, $Limit
        Invoke-WebRequest -Uri $Uri | Out-Null
    }
    catch {
        Log $_
        throw
    }
}

function Invoke-Api ([String]$HostAddress) {
    $api = "http://$HostAddress/api"
    try {
        $sno = Invoke-RestMethod -Uri "$api/sno/"
        $ep = Invoke-RestMethod -Uri "$api/sno/estimated-payout"
        $sno | Add-Member -NotePropertyName "estimatedPayout" -NotePropertyValue $ep
        return $sno
    }
    catch {
        Log $_
        return
    }
}

function ConvertTo-Terabytes ([long]$Bytes) {
    [Math]::Round($Bytes / [Math]::Pow(10, 12), 3)
}

function ConvertTo-Dollar ([int]$DollarCents) {
    [Math]::Round($DollarCents / 100, 2)
}

function Log ($e) {
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $Value = "{0} {1} @ Ln {2}, Col {3}" -f $TimeStamp, $e, $e.InvocationInfo.ScriptLineNumber, $e.InvocationInfo.OffsetInLine
    Add-Content -Path "StorageNodeStats.log" -Value $Value
}

Main
