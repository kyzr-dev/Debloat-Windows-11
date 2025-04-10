function Get-MfgPackages {
    param(
        # Define what type of packages you want to get
        [Parameter(Mandatory = $true)]
        [ValidateSet('Package', 'AppxPackage', 'AppxProvisionedPackage')]
        [string]$Type,

        # Optionally decide if you want the returned data list to contain plain-text strings of PSObjects
        [Parameter(Mandatory = $false)]
        [ValidateSet('StringName', 'Object')]
        [string]$Return = 'Object'
    )

    Request-Elevation -Path $PSCommandPath

    $mfg = Get-ComputerMfg
    $searchName = "*croso*"

    $Packages = Get-Package $($searchName) | Where-Object -Property ProviderName -eq "Programs"
    $AppxPackages = Get-AppxPackage | Where-Object -Property Publisher -like $($searchName) 
    $AppxProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object -Property DisplayName -like $($searchName) 
    
    [Array]$Dataset = switch ($Type) {
        'Package'                    { $Packages }
        'AppxPackage'                { $AppxPackages }
        'AppxProvisionedPackage'     { $AppxProvisionedPackages }
    }
    
    [Array]$ReadableDataset = $Dataset | ForEach-Object {
        [PSCustomObject]@{
            Name = if ($Type -eq 'AppxProvisionedPackage') { $_.DisplayName } else { $_.Name }
        }
    }
    
    $Output = "$($Type)s that reference your computer's manufacturer ($($mfg)):"
    if ($Dataset.Length -eq 0){
        $Output = ("There are no", $Output.Replace(":", "."))
    }  
    
    Write-Host $Output -ForegroundColor Yellow

    switch ($Return) {
        'StringName' { return $ReadableDataset}
        'Object'     { return $Dataset }
    }
}
