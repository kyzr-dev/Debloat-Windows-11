function Get-RAMUsage {
    param(
        [Parameter(Mandatory = $true)][string]$Hostname
    )

function ConvertTo-Num {
    param (
        [string]$stringData
    )
    return [long]$stringData
}


    $totalString = Invoke-Command -ComputerName $Hostname { (Get-CimInstance win32_computersystem).TotalPhysicalMemory }
    $freeString = (wmic /node:$Hostname OS get FreePhysicalMemory | Out-String)

    $freeString = $freeString.Replace([regex]::new("FreePhysicalMemory"), "")
    $total = ( ConvertTo-Num -StringData $totalString )
    $free = ( ConvertTo-Num -StringData $freeString )
    $freeBytes = $free * 1024
    $usedBytes = $total - $freeBytes
    $usedPercent = [math]::Round(($usedBytes / $total) * 100, 2)
    return "$usedPercent%"

}
