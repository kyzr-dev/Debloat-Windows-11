param (
	$exPol = $null
)

# Confirm before continuing (

Add-Type -AssemblyName System.Windows.Forms
$confirmContinue = [System.Windows.Forms.MessageBox]::Show("Windows Debloat will automatically uninstall several apps and Windows components without prompt for confirmation? `n`nContinue?",'KYZR - Windows Debloat','YesNo','Question')

Switch ($confirmContinue) {
	'Yes' { continue }
	'No' { exit }
}

# )

# Set up logging (
$logDir = "$PSScriptRoot\Logs\$env:COMPUTERNAME"

$logFiles = @(
	$rmvLog = "RemovePackages.log";
	$edgeLog = "MakeEdgeUninstallable.log";
	$userRegLog = "UserRegistry.log";
	$groundworkLog = "Groundwork.log";
	$shredOneDriveLog = "ShredOneDrive.log"
)


if (-not (Test-Path $logDir)){
	New-Item -Path $logDir -ItemType "Directory" -Force
}

foreach($log in $logFiles){
	New-Item -Path $logDir -Name $log -ItemType "File" -Force
}

function Get-Timestamp{
    $ts = (Get-Date).ToString("HH:mm:ss")
    return $ts
}

# )

# Add custom module to runtime environment (
Import-Module -DisableNameChecking $PSScriptRoot\modules\Hijack.psm1
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
		Write-Progress -Activity 'Preparing Windows to ensure debloat can succeed..' -PercentComplete $complete;
		& $script;
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
	sp "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1

	Write-Output "[$(Get-Timestamp)] Removing OneDrive leftovers trash"
	Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue 
	Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue 
	Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue 

	Write-Output "[$(Get-Timestamp)] Removing Onedrive from explorer sidebar.."
	New-PSDrive -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -Name "HKCR"
	mkdir -Force "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
	sp "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
	mkdir -Force "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
	sp "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
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
	foreach ($item in (ls "$env:WINDIR\WinSxS\*onedrive*")) {
		Hijack-Path $item.FullName
		Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
	}
} *>&1 >> "$logDir\$shredOneDriveLog"
# ) 

# Remove specified packages from Windows if installed (
$selectors = @(
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
);
$getCommand = {
  Get-AppxProvisionedPackage -Online;
};
$filterCommand = {
  $_.DisplayName -eq $selector;
};
$removeCommand = {
  [CmdletBinding()]
  param(
    [Parameter( Mandatory, ValueFromPipeline )]
    $InputObject
  );
  process {
    $InputObject | Remove-AppxProvisionedPackage -AllUsers -Online -ErrorAction 'Continue';
  }
};

function Remove-Copilot {
    $COPILOT = Get-AppxPackage | Where-Object {$_.Name -match "Copilot"}
    $COPILOT | Remove-AppxProvisionedPackage -AllUsers -Online -ErrorAction 'Continue'
    $COPILOT | Remove-AppxPackage
    Get-AppxPackage -Name 'Microsoft.Windows.Ai.Copilot.Provider' | Remove-AppxPackage
}

$type = 'Package';

&{
	$installed = & $getCommand;
	foreach( $selector in $selectors ) {
		$result = [ordered] @{
			Selector = $selector;
		};
		$found = $installed | Where-Object -FilterScript $filterCommand;
		if( $found ) {
			$result.Output = $found | & $removeCommand;
			if( $? ) {
				$result.Message = "$type removed.";
			} else {
				$result.Message = "$type not removed.";
				$result.Error = $Error[0];
			}
		} else {
			$result.Message = "$type not installed.";
		}
		$result | ConvertTo-Json -Depth 3 -Compress;
	}
	
	& Remove-Copilot
	
} *>&1 >> "$logDir\$rmvLog"
# )

# Make Microsoft Edge uninstallable (
$ErrorActionPreference = 'Stop';
& {
	$isrPolicySet = 'C:\Windows\System32\IntegratedServicesRegionPolicySet.json'
	Hijack-Path -FilePath $isrPolicySet
	try {
		$params = @{
			LiteralPath = $isrPolicySet;
			Encoding = 'Utf8';
		};
		$o = Get-Content @params | ConvertFrom-Json;
		$o.policies | ForEach-Object -Process {
			if( $_.guid -eq '{1bca278a-5d11-4acf-ad2f-f9ab6d7f93a6}' ) {
				$_.defaultState = 'enabled';
			}
		};
		$o | ConvertTo-Json -Depth 9 | Out-File @params;
	} catch {
		$_;
	}
} *>&1 >> "$logDir\$edgeLog";
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
	schtasks /create /tn "Fix ExecutionPolicy" /sc onlogon /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command Set-ExecutionPolicy $exPol -Scope LocalMachine -Force ; schtasks /delete /tn 'Fix ExecutionPolicy' /f" /ru SYSTEM /rl highest /f
	
}

# Prompt for reboot (
$promptReboot = [System.Windows.Forms.MessageBox]::Show("Windows Content Delivery Manager has been queued for removal, but will not be fully removed until next restart. `n`nReboot now?",'KYZR - Windows Debloat','YesNo','Question')

Switch ($promptReboot) {
	'Yes' { Start-Process cmd.exe -ArgumentList "/c shutdown /r /t 1" -Verb RunAs }
	'No' { [System.Windows.MessageBox]::Show("Content Delivery Manager will attempt to reinstall bloatware and other components that were removed by this script. `n`nConsider rebooting ASAP or risk debloat being undone.",'KYZR - Windows Debloat','OK','Information') }
}
# )
