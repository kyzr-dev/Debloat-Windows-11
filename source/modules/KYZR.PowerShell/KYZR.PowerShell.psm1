param (
	[hashtable]$Arguments = @{
		Instance = $null # String (path)
        LogDirectory = $null # String (path)
        LogFiles = $null # List (of file names)
	}
)

$script:ErrorLib = @{
    ERR_NULL_LOG_DIR = "Could not resolve log directory because it is null."
    
}

$script:Config = @{
    ImportedBy = $null
    CurrentLogDir = $null
}

$directorySeparator = [System.IO.Path]::DirectorySeparatorChar
$moduleName = $PSScriptRoot.Split($directorySeparator)[-1]
$moduleManifest = $PSScriptRoot + $directorySeparator + $moduleName + '.psd1'
$publicFunctionsPath = $PSScriptRoot + $directorySeparator + 'Public' + $directorySeparator + 'ps1'
$privateFunctionsPath = $PSScriptRoot + $directorySeparator + 'Private' + $directorySeparator + 'ps1'
$currentManifest = Test-ModuleManifest $moduleManifest

$aliases = @()
$variables = @()
$publicFunctions = Get-ChildItem -Path $publicFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$privateFunctions = Get-ChildItem -Path $privateFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$publicFunctions | ForEach-Object { . $_.FullName }
$privateFunctions | ForEach-Object { . $_.FullName }

$publicFunctions | ForEach-Object { # Export all of the public functions from this module

    # The command has already been sourced in above. Query any defined aliases.
    $alias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
    if ($alias) {
        $aliases += $alias
        Export-ModuleMember -Function $_.BaseName -Alias $alias
    }
    else {
        Export-ModuleMember -Function $_.BaseName
    }
}

$variablesAdded = $variables | Where-Object {$_ -notin $currentManifest.ExportedVariables.Keys}
$variablesRemoved = $variables.ExportedVariables.Keys | Where-Object {$_ -notin $variables}
$functionsAdded = $publicFunctions | Where-Object {$_.BaseName -notin $currentManifest.ExportedFunctions.Keys}
$functionsRemoved = $currentManifest.ExportedFunctions.Keys | Where-Object {$_ -notin $publicFunctions.BaseName}
$aliasesAdded = $aliases | Where-Object {$_ -notin $currentManifest.ExportedAliases.Keys}
$aliasesRemoved = $currentManifest.ExportedAliases.Keys | Where-Object {$_ -notin $aliases}

if ($functionsAdded -or $functionsRemoved -or $aliasesAdded -or $aliasesRemoved -or $variablesAdded -or $variablesRemoved) {
    try {
        $updateModuleManifestParams = @{}
        $updateModuleManifestParams.Add('Path', $moduleManifest)
        $updateModuleManifestParams.Add('ErrorAction', 'Stop')
        if ($aliases.Count -gt 0) { $updateModuleManifestParams.Add('AliasesToExport', $aliases) }
        if ($publicFunctions.Count -gt 0) { $updateModuleManifestParams.Add('FunctionsToExport', $publicFunctions.BaseName) }
        if ($variables.Count -gt 0) { $updateModuleManifestParams.Add('VariablesToExport', $variables)}
        Update-ModuleManifest @updateModuleManifestParams
    }
    catch {
        $_ | Write-Error
    }
}

if ($($Arguments.Instance)){ # If the module was imported by a script, and made aware of its filepath. The instance's information is used to create a log folder:
    $instance = Get-Item $($Arguments.Instance)
    try { (Test-Path $instance.Directory.Parent) | Out-Null ; $logDir = $instance.Directory.Parent.FullName } catch { $logDir = $instance.DirectoryName }
    $fileName = $instance.Name
    $segments = @($logDir, "KYZR.Logs", $env:COMPUTERNAME, $fileName)
    $fullPath = $segments -join $directorySeparator
	$fullLogPath = $fullPath.replace(".ps1", "")
    if (-not ($($Arguments.LogDirectory))){   # If no log directory was defined during import.
        $Config.CurrentLogDir = $fullLogPath # Define the default location for potential log folder. Will not be created until 'New-LogFile' is called.
        Write-Host "`nNo log path was defined during import. Setting log directory to default path: $($Config.CurrentLogDir)`n"
    } else { # A path was passed to the module during import.
        Write-Host "`nA log path was defined during import. Setting log directory to defined path: $($Arguments.LogDirectory)`n"
        Set-LogDirectory -Path $($Arguments.LogDirectory) # Define log directory to the path that was passed during import.
        New-LogFile -FileNames $($Arguments.LogFiles) # If a log directory was manually set during import, may as well create the folder automatically.

    }
} else { Write-Host "No Instance" }

