function Get-UserInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$User,
        [Parameter(Mandatory=$true)]
        [ValidateSet('Email', 'Name', 'SID')]
        [string]$Property
    )

    if (-not ( $User )){
        $User = Read-Host -Prompt "Enter user to retrieve their email"
    }

    $Lookup = switch ($Property){
        'Email' {
            {param([string]$Username) Get-ADUser $Username| Select-Object -ExpandProperty UserPrincipalName}
        }
        'Name' {
            {param([string]$Username) Get-ADUser $Username| Select-Object -ExpandProperty Name}
        }
        'SID' {
            {param([string]$Username) Get-ADUser $Username| Select-Object -ExpandProperty SID}
        }
    }

    return Invoke-Command -ComputerName "OVERLAND-DC03" -ScriptBlock $Lookup -ArgumentList "$User"
}