function Get-ComputerInfo {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Hostname,

		[Parameter(Mandatory = $true)]
		[ValidateSet('RAM%', 'CPU%', 'OS', 'MAKE', 'MODEL')]
		[string]$Component
	)

	$Get = switch ($Component){
		'RAM%'{
			function ConvertTo-Num {
				param (
					[string]$stringData
				)
				return [long]$stringData
			}
			$totalString = Invoke-Command -ComputerName $Hostname { (Get-CimInstance win32_ComputerSystem).TotalPhysicalMemory }
			$freeString = Invoke-Command -ComputerName $Hostname { (Get-CimInstance win32_OperatingSystem).FreePhysicalMemory }
			$total = ( ConvertTo-Num -StringData $totalString )
			$free = ( ConvertTo-Num -StringData $freeString )
			$freeBytes = $free * 1024
			$usedBytes = $total - $freeBytes
			$usedPercent = [math]::Round(($usedBytes / $total) * 100, 2)
			return "$usedPercent%"
		}

		'CPU%'{
			$cpuPercent = Invoke-Command -ComputerName $Hostname { (Get-CimInstance win32_Processor).LoadPercentage }
			return "$cpuPercent%"
		}

		'OS'{
			$os = Invoke-Command -ComputerName $Hostname { (Get-CimInstance win32_OperatingSystem).Caption }
			return $os
		}

		'MAKE'{
			$mfg = Invoke-Command -ComputerName $Hostname { (Get-CimInstance win32_ComputerSystem).Manufacturer }
			return $mfg
		}

		'MODEL'{
			$model = Invoke-Command -ComputerName $Hostname { (Get-CimInstance win32_ComputerSystem).Model }
			return $model
		}

	}

	return (& $Get)
}