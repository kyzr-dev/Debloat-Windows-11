function Install-Chocolatey {
    
    [CmdletBinding()]
    param (
    )

    begin {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        if (-not(Confirm-AdminPrivilege)){
            Start-Process -Verb RunAs PowerShell -ArgumentList "-ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Path"
        }
    }

    process {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        $choco = Start-Job -Name "Install Chocolatey" -ScriptBlock {Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))}
        Wait-Job $choco
    }

    end {
        Remove-Job $choco
    }
}