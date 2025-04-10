function Get-ComputerMfg {
    $mfg = (Get-CimInstance win32_computersystem).Manufacturer
    $mfg = $mfg.ToUpper()
    $mfg = $mfg.Split(" ")[0]
    $mfg = $mfg -replace '[\r\n]+', ''
    return $mfg
}