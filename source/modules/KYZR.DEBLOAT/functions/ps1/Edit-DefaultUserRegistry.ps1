function Edit-DefaultUserRegistry {

    Write-Timestamp "Ensuring registry changes persist to all future user accounts.."

    $ErrorActionPreference = 'Stop'
    $defHive = "$env:SystemDrive\Users\Default\NTUSER.DAT"

    reg load HKU\Def $defHive >$null

    try {
		Set-ItemProperty -LiteralPath 'Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Type 'DWord' -Value 0
		
        reg add "HKU\Def\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f
        reg add "HKU\Def\Software\Policies\Microsoft\Windows\CloudContent"  /v DisableConsumerFeatures   /t REG_DWORD /d 1 /f
        reg add "HKU\Def\Software\Policies\Microsoft\Windows\Explorer"      /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f
        reg add "HKU\Def\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f

        Remove-ItemProperty -LiteralPath 'Registry::HKU\Def\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDriveSetup' -Force -ErrorAction SilentlyContinue

        # Content Delivery Manager toggles (disable suggestions, tips, preinstalls)
        $cdm = 'HKU\Def\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
        reg add $cdm /f
        $names = @(
            'ContentDeliveryAllowed','FeatureManagementEnabled','OEMPreInstalledAppsEnabled','PreInstalledAppsEnabled',
            'PreInstalledAppsEverEnabled','SilentInstalledAppsEnabled','SoftLandingEnabled','SubscribedContentEnabled',
            'SubscribedContent-310093Enabled','SubscribedContent-338387Enabled','SubscribedContent-338388Enabled',
            'SubscribedContent-338389Enabled','SubscribedContent-338393Enabled','SubscribedContent-353698Enabled',
            'SystemPaneSuggestionsEnabled'
        )
        foreach ($name in $names) { reg add $cdm /v $name /t REG_DWORD /d 0 /f }
    }

    catch {

        Write-Warning "`n[$(Get-Timestamp)] An error occurred while altering default user registry hive: $($_.Exception.Message)"

    }
    
    finally {

        reg unload HKU\Def >$null

    }
}