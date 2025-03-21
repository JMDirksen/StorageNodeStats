$ErrorActionPreference = "Stop"

function Main {
    try {
        $Settings = Get-Settings .\StorageNodeStats.json

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
            ((Get-Date).ToString("yyyy-MM-dd HH:mm")),
            (ConvertTo-Terabytes -Bytes $TotalDisk),
            (ConvertTo-Terabytes -Bytes $TotalDiskUsed),
            (ConvertTo-Terabytes -Bytes $TotalBandwidthUsed),
            (ConvertTo-Dollar -DollarCents $TotalPayout),
            (ConvertTo-Dollar -DollarCents $TotalExpectedPayout),
            "=MAX(0\; INDIRECT(ADDRESS(ROW()\; COLUMN()-3))-INDIRECT(ADDRESS(ROW()-1\; COLUMN()-3)))",
            "=MAX(0\; INDIRECT(ADDRESS(ROW()\; COLUMN()-3))-INDIRECT(ADDRESS(ROW()-1\; COLUMN()-3)))"
        )

        $Uri = "https://script.google.com/macros/s/{0}/exec?stats={1}&limit={2}" -f @(
            # Google Apps Script Deployment ID
            $Settings.DeploymentID,
            # Joined stats
            ($Stats -join ";"),
            # Row limit
            ($Settings.KeepDays * 24 * 60 / $Settings.IntervalMinutes)
        )
        Invoke-WebRequest -Uri $Uri | Out-Null
    }
    catch {
        Log -Message "Error in Main." -Exception $_
        throw
    }
}

function Get-Settings ([string]$FileName) {
    If (-not (Test-Path $FileName)) {
        $Settings = @{}
        $Settings.Hosts = @('localhost')
        $Settings.DeploymentID = ""
        $Settings.KeepDays = 60
        $Settings.IntervalMinutes = 180
        $Settings | ConvertTo-Json | Set-Content -Path $FileName
    }
    Get-Content -Path $FileName | ConvertFrom-Json
}

function Invoke-Api ([string]$HostAddress) {
    $api = "http://$HostAddress/api"
    try {
        $sno = Invoke-RestMethod -Uri "$api/sno/"
        $ep = Invoke-RestMethod -Uri "$api/sno/estimated-payout"
        $sno | Add-Member -NotePropertyName "estimatedPayout" -NotePropertyValue $ep
        return $sno
    }
    catch {
        Log -Message "Error connecting to $api." -Exception $_
        return
    }
}

function ConvertTo-Terabytes ([long]$Bytes) {
    [Math]::Round($Bytes / [Math]::Pow(10, 12), 3)
}

function ConvertTo-Dollar ([int]$DollarCents) {
    [Math]::Round($DollarCents / 100, 2)
}

function Log ([string]$Message, [System.Management.Automation.ErrorRecord]$Exception) {
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $Value = "{0} {1} {2} @ Ln {3}, Col {4}" -f $TimeStamp, $Message, $Exception, $Exception.InvocationInfo.ScriptLineNumber, $Exception.InvocationInfo.OffsetInLine
    Add-Content -Path "StorageNodeStats.log" -Value $Value
}

Main
