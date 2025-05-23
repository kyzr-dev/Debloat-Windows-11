function Get-CPUUsage {
    param(
        [Parameter(Mandatory = $true)][string]$Hostname
    )
    $cpuString = (wmic /node:MIS5 cpu get loadpercentage | Out-String)
    $pattern = [regex]::New("[A-Za-z`n]")
    $cpuString = $cpuString -replace $pattern, ""
    $cpuPercent = [long]$cpuString
    return "$cpuPercent%"
}

