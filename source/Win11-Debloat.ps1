# Add custom module to runtime environment (
Import-Module -DisableNameChecking "$PSScriptRoot\modules\KYZR.PowerShell\KYZR.PowerShell.psm1" -ArgumentList @{ Instance = $PSCommandPath }

# )

if (-not (Confirm-Elevation)){
	Request-Elevation -Path $PSCommandPath
	exit
}

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
		reg.exe add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /v NoRemove /t REG_DWORD /d 0 /f;
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
