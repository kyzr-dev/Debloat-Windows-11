function Write-Timestamp {
    param(
        [Parameter(Position=0)]
        [string] $Message
    )
    $output = "$Message`n"
    Write-Host "`n[$(Get-Timestamp)] $output" -NoNewline

}