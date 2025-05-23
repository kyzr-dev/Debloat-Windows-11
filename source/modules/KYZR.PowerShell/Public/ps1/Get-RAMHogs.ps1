function Get-RAMHogs{
	param(
		$Hostname = $null
	)
	
	if ($Hostname -eq $null){
		$Hostname = Read-Host -Prompt "Enter computer name to check top users of RAM"
	}
	
	Invoke-Command -ComputerName $Hostname -ScriptBlock{
		Get-Process -IncludeUserName |
		  Sort-Object -Property WorkingSet64 -Descending
	}  | Select-Object -First 15 Name, Id, @{Name="MemoryUsageMB";Expression={[math]::Round($_.WorkingSet64 / 1MB,1)}}
	
}