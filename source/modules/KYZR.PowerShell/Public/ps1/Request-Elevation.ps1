function Request-Elevation {
    param (
        [parameter(Mandatory=$false)][string]$Path
    )

    if (Confirm-Elevation){
        $Host.UI.RawUI.WindowTitle = "Windows PowerShell - KYZR (Elevated)"
        return 
        } else {
            if ($Path){
                if (-not (Test-Path $Path)){
                    Assert-Error -Code ERR_INVALID_PATH -Params @{ Path = $Path } -ExceptionType ([System.IO.FileNotFoundException])
                } else {
                    Start-Process -Verb RunAs PowerShell -ArgumentList "-NoExit -ExecutionPolicy Bypass -File $Path -ArgumentList $args"
                }
            } else {
                Start-Process -Verb RunAs PowerShell
            }
		    $Host.UI.RawUI.WindowTitle = "Windows PowerShell - KYZR (Elevated)"
        }
}
