function Remove-Bloatware{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, ValueFromPipeline)][string[]] $PackageList
	)

    if ($null -eq $PackageList){
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

    } else {
        $AppPatterns = $PackageList
      }

	Request-Elevation -Path $PSCommandPath

	Write-Output "[$(Get-Timestamp)] Starting bloatware removal..."

	# Cache installed and provisioned apps for performance
	$InstalledApps = Get-AppxPackage -AllUsers
	$ProvisionedApps = Get-AppxProvisionedPackage -Online

	foreach ($Pattern in $AppPatterns) {
		# Find matches for installed apps
		$MatchingInstalledApps = $InstalledApps | Where-Object { $_.Name -like $Pattern }
		foreach ($App in $MatchingInstalledApps) {
			try {
				Write-Output "[$(Get-Timestamp)] Removing installed app: $($App.Name)"
				$App | Remove-AppxPackage -AllUsers -ErrorAction Stop
			}
			catch {
				Write-Warning "[$(Get-Timestamp)] Failed to remove installed app: $($App.Name) - $($_.Exception.Message)"
				"[$(Get-Timestamp)] ERROR removing installed app: $($App.Name) - $($_.Exception.Message)"
			}
		}

		# Find matches for provisioned apps
		$MatchingProvisionedApps = $ProvisionedApps | Where-Object { $_.DisplayName -like $Pattern }
		foreach ($ProvApp in $MatchingProvisionedApps) {
			try {
				Write-Output "[$(Get-Timestamp)] Removing provisioned app: $($ProvApp.DisplayName)"
				Remove-AppxProvisionedPackage -Online -PackageName $ProvApp.PackageName -ErrorAction Stop
			}
			catch {
				Write-Warning "[$(Get-Timestamp)] Failed to remove provisioned app: $($ProvApp.DisplayName) - $($_.Exception.Message)"
				"[$(Get-Timestamp)] ERROR removing provisioned app: $($ProvApp.DisplayName) - $($_.Exception.Message)"
			}
		}
	}

	Write-Output "[$(Get-Timestamp)] Bloatware removal completed."
}
