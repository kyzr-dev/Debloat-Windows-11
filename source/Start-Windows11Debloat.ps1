
param (
    [Parameter()]
    [switch]$Unattended
)

Import-Module "$PSScriptRoot\modules\KYZR.DEBLOAT\KYZR.DEBLOAT.psm1" -ErrorAction Stop

# Prompt for user confirmation if not running headless
if (-not $Unattended){

    $confirmMessageParameter = @{
	Message = "This tool will automatically uninstall several apps and Windows components with no other prompt for confirmation after this warning. `n`nContinue?"
	WindowTitle = 'KYZR - Windows Debloat'
	Buttons = "YesNo"
	Icon = 'Question'
}

    $confirmContinue = New-MessageBox @confirmMessageParameter
    switch ($confirmContinue) {
        'No' { exit }
    }

}

# Logging init
$logDir = 'C:\Logs'; if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

Start-Transcript -Path "$logDir\debloat.log" -Append
Write-Timestamp "Starting.."

# Some miscellaneous groundwork before debloat 
Invoke-RegistryPolicy

# Shred OneDrive and all of its fingerprints 
Remove-OneDrive

# Purge bloatware using a list of package names
Remove-Bloatware

# Edit default user registry to persist changes onto all new user accounts
Edit-DefaultUserRegistry

Write-Timestamp "Debloat complete."
Stop-Transcript

# Prompt for reboot if not running headless
if (-not $Unattended){

    $rebootMessageParameter = @{
        Message = "Debloat complete (see log file for details: 'C:\Logs\debloat.log').`n`nWindows Content Delivery Manager has been queued for removal, but will not be fully removed until next restart. `n`nReboot now?"
        WindowTitle = 'KYZR - Windows Debloat'
        Buttons = "YesNo"
        Icon = 'Question'
    }

    $doubledownParameter = @{
        Message = "Content Delivery Manager will attempt to reinstall bloatware and other components that were removed by this script. `n`nConsider rebooting ASAP or risk debloat being undone."
        WindowTitle = 'KYZR - Windows Debloat'
        Buttons = "Ok"
        Icon = 'Information'
    }

    $agreedReboot = New-MessageBox @rebootMessageParameter

    switch ($agreedReboot) {
        'Yes' { Start-Process cmd.exe -ArgumentList "/c shutdown /r /t 2" -Verb RunAs }
        'No' { New-MessageBox @doubledownParameter}
    }

}


if ((-not $Unattended) -and (-not $agreedReboot -eq 'Yes')){ 
    if ( Test-Path "C:\Logs" ) { Start-Process explorer -ArgumentList "C:\Logs" } 
}

exit

