function Invoke-RegistryPolicy {

    Write-Timestamp "Applying registry policy.."

    try {
		
		Set-ItemProperty -LiteralPath 'Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Type 'DWord' -Value 0

        Write-Timestamp "Removing DevHome update scheduler.."
        Remove-Item -LiteralPath 'Registry::HKLM\Software\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate' -Force -ErrorAction SilentlyContinue
		
        Write-Timestamp "Disabling Outlook auto re-install.."
        Remove-Item -LiteralPath 'Registry::HKLM\Software\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' -Force -ErrorAction SilentlyContinue

        Write-Timestamp "Disabling Start Menu's `"from the web`" search suggestions.."
		reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f

        Write-Timestamp "Disabling Copilot.."
		reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f
        
        Write-Timestamp "Disabling Edge sidebar.."
		reg add "HKLM\Software\Policies\Microsoft\Edge" /v HubsSidebarEnabled /t REG_DWORD /d 0 /f

        Write-Timestamp "Squelching Edge's `"first run experience`".."
		reg add "HKLM\Software\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f

        Write-Timestamp "Disabling automatic `"optimized content`" delivery.."
		reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableCloudOptimizedContent /t REG_DWORD /d 1 /f

        Write-Timestamp "Disabling news and interests sidebar.."
		reg add "HKLM\Software\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f

        Write-Timestamp "Disabling widgets sidebar.."
		reg add "HKLM\Software\Policies\Microsoft\Dsh" /v AllowWidgets /t REG_DWORD /d 0 /f

        Write-Timestamp "Disabling local network content fetching.."
		reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f
	  
        $tasks = @(
            '\Microsoft\Windows\CloudExperienceHost\CreateObjectTask',
            '\Microsoft\Windows\Shell\FamilySafetyMonitor'
        )

        Write-Timestamp "Attempting to disable some scheduled tasks related to content delivery and consumer features.."
        foreach ($t in $tasks) { schtasks /Change /TN $t /Disable 2>$null }

        Write-Timestamp "Attempting to disable several Content Delivery Manager components (suggestions, tips, preinstalls, etc.)"
        $cdm = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'

        reg add $cdm /f

        $names = @(
            'ContentDeliveryAllowed','FeatureManagementEnabled','OEMPreInstalledAppsEnabled','PreInstalledAppsEnabled',
            'PreInstalledAppsEverEnabled','SilentInstalledAppsEnabled','SoftLandingEnabled','SubscribedContentEnabled',
            'SubscribedContent-310093Enabled','SubscribedContent-338387Enabled','SubscribedContent-338388Enabled',
            'SubscribedContent-338389Enabled','SubscribedContent-338393Enabled','SubscribedContent-353698Enabled',
            'SystemPaneSuggestionsEnabled'
        )

        foreach ($name in $names) { reg add $cdm /v $name /t REG_DWORD /d 0 /f }

    # Some extra (necessary) steps for the MS Teams registry key(s):
        $teamsRegKeyString = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications'
        $autoInstallTeamsValue = 'ConfigureChatAutoInstall'

    # i.) Take ownership
        Write-Timestamp "Attempting to take ownership of a registry key.."
        Unlock-RegACL $teamsRegKeyString

    # ii.) Make the change
        Set-ItemProperty -Path $teamsRegKeyString -Name $autoInstallTeamsValue -Type DWord -Value 0 -Force

        if ($?){ Write-Timestamp "Successfully altered the value of a priviliged registry item." }
        
    # iii.) Restore ownership to TrustedInstaller

        $trustedInstaller = [System.Security.Principal.NTAccount]'NT SERVICE\TrustedInstaller'

        Write-Timestamp "Reverting registry key ownership.."
        Unlock-RegACL -LiteralKey $teamsRegKeyString -Owner $trustedInstaller

    } 
    catch {

        Write-Warning "`n[$(Get-Timestamp)] An error occurred during registry policy application: $($_.Exception.Message)"

    }

}