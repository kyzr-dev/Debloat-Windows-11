function Request-Elevation {
    param (
        [parameter(Mandatory=$false)][string]$Path
    )

    $Elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $ERR_INVALID_PATH = "Could not open `'$Path`' with elevated privileges because the path does not exist."

    if ($Elevated){
        $Host.UI.RawUI.WindowTitle = "Windows PowerShell - KYZR (Elevated)"
        return 
        } else {
            if ($Path){
                if (-not (Test-Path $Path)){
                    throw $ERR_INVALID_PATH
                } else {
                    Start-Process -Verb RunAs PowerShell -ArgumentList "-NoExit -ExecutionPolicy Bypass -File $Path"
                }
            } else {
                Start-Process -Verb RunAs PowerShell
            }
		    $Host.UI.RawUI.WindowTitle = "Windows PowerShell - KYZR (Elevated)"
        }
}