function Set-LogDirectory{
	param (
        [parameter(Mandatory=$true)][string]$Path
    )
	$Config.CurrentLogDir = $Path

}