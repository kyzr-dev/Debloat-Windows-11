function Remove-Bloatware {

    [string[]]$AppPatterns = @(
        'Microsoft.Microsoft3DViewer';
        'Microsoft.BingSearch';
        'Microsoft.Copilot';
        'Clipchamp.Clipchamp';
        'Microsoft.549981C3F5F10';
        'Microsoft.Windows.DevHome';
        'MicrosoftCorporationII.MicrosoftFamily';
        'Microsoft.Getstarted';
        'microsoft.windowscommunicationsapps';
        'Microsoft.MixedReality.Portal';
        'Microsoft.BingNews';
        'Microsoft.MicrosoftOfficeHub';
        'Microsoft.Office.OneNote';
        'Microsoft.OutlookForWindows';
        'Microsoft.People';
        'Microsoft.SkypeApp';
        'Microsoft.MicrosoftSolitaireCollection';
        'MicrosoftTeams';
        'MSTeams';
        'Microsoft.Todos';
        'Microsoft.Wallet';
        'Microsoft.BingWeather';
        'Microsoft.Xbox.TCUI';
        'Microsoft.XboxApp';
        'Microsoft.XboxGameOverlay';
        'Microsoft.XboxGamingOverlay';
        'Microsoft.XboxIdentityProvider';
        'Microsoft.XboxSpeechToTextOverlay';
        'Microsoft.GamingApp';
        'Microsoft.YourPhone';
        'Microsoft.ZuneMusic';
        'Microsoft.ZuneVideo';
        'Microsoft.Whiteboard';
        'Microsoft.MicrosoftOfficeHub';
        'Microsoft.Windows.Ai.Copilot.Provider';
        'Copilot';

    ) 

	Write-Timestamp "Starting bloatware removal.."

	# Cache installed and provisioned apps for performance
    $InstalledApps    = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    $ProvisionedApps  = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

    foreach ($Pattern in $AppPatterns) {

        $MatchingProvisionedApps = $ProvisionedApps | Where-Object { $_.DisplayName -like $Pattern }
        $MatchingInstalledApps   = $InstalledApps   | Where-Object { $_.Name        -like $Pattern }

        foreach ($ProvApp in $MatchingProvisionedApps) {
            try {
                Write-Timestamp "Attempting to remove a provisioned package: $($ProvApp.PackageName)"
                $null = Remove-AppxProvisionedPackage -Online -PackageName $ProvApp.PackageName -ErrorAction Stop
            } catch {
                if ($_.Exception.Message -like "*path specified*") {    # Continue if package is not installed
                    Write-Verbose "Skipping missing provisioned app: $($ProvApp.PackageName)"
                } else {
                    $ERR_PROV_PACKAGE_REMOVAL = "[{0}] Failed to remove provisioned: {1} - {2}" -f (Get-Timestamp), $ProvApp.DisplayName, $_.Exception.Message
                    throw $ERR_PROV_PACKAGE_REMOVAL     # Only throw on exceptions not related to missing package name
                }
            }
        }

        foreach ($App in $MatchingInstalledApps) {
            try {
                Write-Timestamp "Attempting to remove an installed package: $($App.PackageFullName)"
                $null = Remove-AppxPackage -Package $App.PackageFullName -AllUsers -ErrorAction Stop
            } catch {

                if ($_.Exception.Message -like "*path specified*") {    # Continue if package is not installed
                    Write-Verbose "Skipping missing provisioned app: $($App.PackageName)"
                } else { 
                    $ERR_PACKAGE_REMOVAL = "[{0}] Failed to remove installed: {1} - {2}" -f (Get-Timestamp), $App.Name, $_.Exception.Message
                    throw $ERR_PACKAGE_REMOVAL      # Only throw on exceptions not related to missing package name
                }
            }
        }

    }
}