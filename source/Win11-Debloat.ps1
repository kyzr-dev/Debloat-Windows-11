param (
	$exPol = [Microsoft.PowerShell.ExecutionPolicy]::RemoteSigned
)

# Add custom module to runtime environment (
Import-Module -DisableNameChecking "$PSScriptRoot\modules\KYZR.PowerShell\KYZR.PowerShell.psm1" -ArgumentList @{ Instance = $PSCommandPath }

# )

$confirmMessageParameter = @{
	Message = "This tool will automatically uninstall several apps and Windows components with no other prompt for confirmation after this warning. `n`nContinue?"
	WindowTitle = 'KYZR - Windows Debloat'
	Buttons = "YesNo"
	Icon = 'Question'
}

$confirmContinue = New-MessageBox @confirmMessageParameter
Switch ($confirmContinue) {
	'No' { exit }
}

# )

# Set up logging (
$rmvLog = "RemovePackages.log";
$edgeLog = "MakeEdgeUninstallable.log";
$userRegLog = "UserRegistry.log";
$groundworkLog = "Groundwork.log";
$shredOneDriveLog = "ShredOneDrive.log"

$logFiles = @(
    $rmvLog;
    $edgeLog;
    $userRegLog;
    $groundworkLog;
    $shredOneDriveLog
)

Initialize-Logging -FileNames $logFiles
$logDir = Get-LogDirectory

# )

# Some miscellaneous groundwork before debloat (
$scripts = @(
	{
		Remove-Item -LiteralPath 'Registry::HKLM\Software\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate' -Force -ErrorAction 'SilentlyContinue';
	};
	{
		Remove-Item -LiteralPath 'Registry::HKLM\Software\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' -Force -ErrorAction 'SilentlyContinue';
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f;
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f;
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Edge" /v HubsSidebarEnabled /t REG_DWORD /d 0 /f;
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f;
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d 1 /f;
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f;
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 0 /f;
	};
	{
		Hijack-RegKey -LiteralKey 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Communications' # Cannot abbreviate root to HKLM
	};
	{
		reg.exe add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Communications' /v ConfigureChatAutoInstall /t REG_DWORD /d 0 /f
	};
);


& {
	[float] $complete = 0;
	[float] $increment = 100 / $scripts.Count;
	foreach( $script in $scripts ) {
		$scriptname = ([string]$script).TrimStart()
		$trimmed = ($scriptname).Trim("`n`r")
		Write-Host "Running some prep scripts."
		Write-Progress -Activity "Currently running: $trimmed" -PercentComplete $complete;
		try{
			& $script
		} catch {
		
		}
		$complete += $increment;
	}
} *>&1 >> "$logDir\$groundworkLog";
# )

# Shred OneDrive and all of its fingerprints (
& {
	Write-Output "[$(Get-Timestamp)] Stopping OneDrive and Explorer processes.."
	taskkill.exe /F /IM "OneDrive.exe"
	taskkill.exe /F /IM "explorer.exe"

	Write-Output "[$(Get-Timestamp)] Removing OneDrive.."
	if (Test-Path "$env:SYSTEMROOT\System32\OneDriveSetup.exe") {
		& "$env:SYSTEMROOT\System32\OneDriveSetup.exe" /uninstall
	}
	if (Test-Path "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe") {
		& "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe" /uninstall
	}

	Write-Output "[$(Get-Timestamp)] Disabling OneDrive via Group Policy.."
	New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive" -ItemType Directory -Force 
	Set-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1

	Write-Output "[$(Get-Timestamp)] Removing OneDrive leftovers trash"
	Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue 
	Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue 
	Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue 

	Write-Output "[$(Get-Timestamp)] Removing Onedrive from explorer sidebar.."
	New-PSDrive -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -Name "HKCR"
	mkdir -Force "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
	Set-ItemProperty "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
	mkdir -Force "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
	Set-ItemProperty "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
	Remove-PSDrive "HKCR"

	Write-Output "[$(Get-Timestamp)] Removing run option for new users.."
	reg load "HKU\Default" "C:\Users\Default\NTUSER.DAT"
	reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f
	reg unload "HKU\Default"

	Write-Output "[$(Get-Timestamp)] Removing OneDrive from Start menu.."
	Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -Recurse -Force -ErrorAction SilentlyContinue

	Write-Output "[$(Get-Timestamp)] Restarting Explorer..."
	Start-Process "explorer.exe"

	Write-Output "[$(Get-Timestamp)] Wait for Explorer to restart before continuing.."
	Start-Sleep 5

	Write-Output "[$(Get-Timestamp)] Removing additional OneDrive leftovers"
	foreach ($item in (Get-ChildItem "$env:WINDIR\WinSxS\*onedrive*")) {
		Write-Output "Attempting to Hijack $item"
		Hijack-Path -FilePath $item.FullName -RemoveACL $true
		Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
	}
} *>&1 >> "$logDir\$shredOneDriveLog"
# ) 

# Remove specified packages from Windows if installed (
function Remove-BloatwareApps {
	[CmdletBinding()]
	param (
		[Parameter()]
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
	
			# Customized / Targeted Packages
			'E0469640.LenovoUtility';                      
			'E0469640.LenovoSmartCommunication';             
			'E046963F.LenovoCompanion';   
		)

	)

	# Ensure we have admin rights
	if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Write-Error "ERROR: You must run this script as Administrator."
		return
	}

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

&{
    Remove-BloatwareApps
} *>&1 >> "$logDir\$rmvLog"
# )

# Make necessary changes to user's reg hive (
$scripts = @(
	{
		reg.exe add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f;
	};
	{
		Remove-ItemProperty -LiteralPath 'Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDriveSetup' -Force -ErrorAction 'Continue';
	};
	{
		reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f;
	};
	{
		$names = @(
		  'ContentDeliveryAllowed';
		  'FeatureManagementEnabled';
		  'OEMPreInstalledAppsEnabled';
		  'PreInstalledAppsEnabled';
		  'PreInstalledAppsEverEnabled';
		  'SilentInstalledAppsEnabled';
		  'SoftLandingEnabled';
		  'SubscribedContentEnabled';
		  'SubscribedContent-310093Enabled';
		  'SubscribedContent-338387Enabled';
		  'SubscribedContent-338388Enabled';
		  'SubscribedContent-338389Enabled';
		  'SubscribedContent-338393Enabled';
		  'SubscribedContent-353698Enabled';
		  'SystemPaneSuggestionsEnabled';
		);
		
		foreach( $name in $names ) {
		  reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v $name /t REG_DWORD /d 0 /f;
		}
	};
	{
		reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f;
	};
	{
		reg.exe add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f;
	};
);

& {
	Write-Output "[$(Get-Timestamp)] Modifying Current User's registry hive..`nSome keys may not exist, but the program will check them all to be thorough."
	[float] $complete = 0;
	[float] $increment = 100 / $scripts.Count;
	foreach( $script in $scripts ) {
		Write-Progress -Activity 'Running scripts to modify the user registry hive. Do not close this window.' -PercentComplete $complete;
		& $script;
		$complete += $increment;
	}
} *>&1 >> "$logDir\$userRegLog";
# )


if (-not({ Get-ExecutionPolicy } -eq $exPol)){
	schtasks /create /tn "Fix ExecutionPolicy" /sc onlogon /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command Set-ExecutionPolicy $exPol -Scope CurrentUser -Force ; schtasks /delete /tn 'Fix ExecutionPolicy' /f" /ru SYSTEM /rl highest /f
	
}

# Prompt for reboot (
$rebootMessageParameter = @{
	Message = "Windows Content Delivery Manager has been queued for removal, but will not be fully removed until next restart. `n`nReboot now?"
	WindowTitle = 'KYZR - Windows Debloat'
	Buttons = "YesNo"
	Icon = 'Question'
}

$doubledownParameter = @{
    Message = "Content Delivery Manager will attempt to reinstall bloatware and other components that were removed by this script. `n`nConsider rebooting ASAP or risk debloat being undone."
    WindowTitle = 'KYZR - Windows Debloat'
	Buttons = "Ok"
	Icon = 'Information'
}


$promptReboot = New-MessageBox @rebootMessageParameter

Switch ($promptReboot) {
	'Yes' { Start-Process cmd.exe -ArgumentList "/c shutdown /r /t 2" -Verb RunAs }
	'No' { New-MessageBox @doubledownParameter}
}

exit
# )
