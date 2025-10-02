$directorySeparator = [System.IO.Path]::DirectorySeparatorChar
$moduleName = $PSScriptRoot.Split($directorySeparator)[-1]
$moduleManifest = $PSScriptRoot + $directorySeparator + $moduleName + '.psd1'
$functionsPath = $PSScriptRoot + $directorySeparator + 'functions' + $directorySeparator + 'ps1'

$aliases = @()
$functions = Get-ChildItem -Path $functionsPath | Where-Object {$_.Extension -eq '.ps1'}
$functions | ForEach-Object { . $_.FullName }

$functions | ForEach-Object {

    $alias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
    if ($alias) {
        $aliases += $alias
        Export-ModuleMember -Function $_.BaseName -Alias $alias
    }
    else {
        Export-ModuleMember -Function $_.BaseName
    }

}

# Update existing manifest
$currentManifest = Test-ModuleManifest $moduleManifest

$functionsAdded = $functions | Where-Object {$_.BaseName -notin $currentManifest.ExportedFunctions.Keys}
$functionsRemoved = $currentManifest.ExportedFunctions.Keys | Where-Object {$_ -notin $functions.BaseName}

$aliasesAdded = $aliases | Where-Object {$_ -notin $currentManifest.ExportedAliases.Keys}
$aliasesRemoved = $currentManifest.ExportedAliases.Keys | Where-Object {$_ -notin $aliases}

if ($functionsAdded -or $functionsRemoved -or $aliasesAdded -or $aliasesRemoved) {
    try {
        $updateModuleManifestParams = @{}
        $updateModuleManifestParams.Add('Path', $moduleManifest)
        $updateModuleManifestParams.Add('ErrorAction', 'Stop')

        if ($aliases.Count -gt 0) { $updateModuleManifestParams.Add('AliasesToExport', $aliases) }
        if ($functions.Count -gt 0) { $updateModuleManifestParams.Add('FunctionsToExport', $functions.BaseName) }

        Update-ModuleManifest @updateModuleManifestParams
    }
    catch {

        $_ | Write-Error
        
    }
}
