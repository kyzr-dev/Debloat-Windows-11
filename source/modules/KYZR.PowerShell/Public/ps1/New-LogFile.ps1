function New-LogFile {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][Array]$FileNames
	)
	
	begin {
		if (-not ($Config.CurrentLogDir)){
			Write-Host "`n[$(Get-Timestamp)] Log directory has not yet been defined.`n" -ForegroundColor Red
			Write-Host "Enter the path where the log folder should be created: " -ForegroundColor Yellow -NoNewLine
			while ($true) {
				$inputPath = Read-Host
				if (Test-Path $inputPath){
					Set-LogDirectory -Path $inputPath
					New-Item -Path $($Config.CurrentLogDir) -ItemType "Directory" -Force
					break
				} else { 
					Clear-Host
					Write-Host "The path you entered does not exist. Enter a valid path: " -ForegroundColor Red -NoNewLine
				  }
			}	
		} else {
			Set-LogDirectory -Path "$($Config.CurrentLogDir)\KYZR.Logs"
			if (-not (Test-Path -LiteralPath $Config.CurrentLogDir)) {
				try {
					New-Item -Path $Config.CurrentLogDir -ItemType Directory -Force | Out-Null
					Write-Host "[$(Get-Timestamp)] Log folder has been created: $($Config.CurrentLogDir)"
				} catch {
					Write-Output "An error occurred when trying to create log folder ($($Config.CurrentLogDir)): $_"
				}
			} else {
				Write-Host "[$(Get-Timestamp)] The folder '$($Config.CurrentLogDir)' already exists. Assigning it as default log directory."
			}
		  }
	}
	
	process {
		if ($FileNames){
			Write-Host "`nOne or more log files were defined. Attempting to create them now.`n"
			foreach($log in $FileNames){
				try {
					New-Item -Path $Config.CurrentLogDir -Name $log -ItemType "File" -Force
					Write-Host "[$(Get-Timestamp)] Successfully created log file: ($($Config.CurrentLogDir)\$log)"
				} catch {
					Write-Output "An error occured when attemping to create a log file ($($Config.CurrentLogDir)\$log): $_"

				}
			}
		}
		else {
			return
		}
	}
	
	end {
		
	}
}
