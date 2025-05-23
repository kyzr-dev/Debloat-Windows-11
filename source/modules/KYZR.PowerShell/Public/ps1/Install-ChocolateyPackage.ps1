function Install-ChocolateyPackage {

    [CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)][string]$PackageName
	)

    begin {
        $msgBoxArguments = @{
            Message = "Attempting to download `'$PackageName`' using a package deployment tool called Chocolatey, which is not currently installed on this computer. Installation cannot continue without it.`n`nWould you like to install it now?"
            WindowTitle = 'KYZR - Install Chocolatey Package'
            Buttons = 'YesNo'
            Icon = 'Exclamation'
        }

        Write-Output "`n[$(Get-Timestamp)] Attempting to install `'$PackageName`' via Chocolatey..`n"
    }

	process {
        if (-not (Test-Path "C:\ProgramData\chocolatey")){
            Write-Output "`n[$(Get-Timestamp)] Chocolatey not detected, prompting for installation.."
            $chocoPrompt = New-MessageBox @msgBoxArguments

            switch ($chocoPrompt){
                'Yes' {
                    try {
                        Install-Chocolatey -Wait
                        while (-not (Test-Path "C:\ProgramData\chocolatey")){
                            Start-Sleep -Seconds 10
                        }
                    } catch {
                        Write-Output "`n[$(Get-Timestamp)] Chocolatey installation failed:  $_"
                        New-MessageBox -Message "Chocolatey could not be installed. Check log file for more information: `"$logDir\$installLog`"" -WindowTitle 'KYZR - Chocolatey Installation Failure' -Buttons "OK" -Icon "Error"
                        exit
                    }
                }
                'No' {
                    exit 
                }
            }
        }
	} 

    end {
        Start-Process "C:\ProgramData\chocolatey\choco.exe" -ArgumentList "install $PackageName -y --force" -Wait
        Write-Output "`n[$(Get-Timestamp)] `'$PackageName`' was successfully installed."
        exit
    }
}