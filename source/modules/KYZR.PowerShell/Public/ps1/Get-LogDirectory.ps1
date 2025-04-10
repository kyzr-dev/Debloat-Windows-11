function Get-LogDirectory {
	if ($null -eq $Arguments.LogDirectory){
		throw $ErrorLib.ERR_NULL_LOG_DIR
	} else {
		return $Arguments.LogDirectory
	}
}

