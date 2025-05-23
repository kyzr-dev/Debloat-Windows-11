function Get-LogDirectory {
	if ($null -eq $Config.CurrentLogDir){
		Assert-Error -Code ERR_VARIABLE_NULL -Params @{Variable="Config.CurrentLogDir"} -ExceptionType ([System.IO.IOException])
	} else {
		return $Config.CurrentLogDir
	}
}
