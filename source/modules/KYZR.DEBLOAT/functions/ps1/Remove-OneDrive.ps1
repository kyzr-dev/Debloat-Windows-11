function Remove-OneDrive {

    Write-Timestamp "Purging OneDrive.."
    $ErrorActionPreference = 'SilentlyContinue'

    try {

        taskkill.exe /F /IM "OneDrive.exe"

        if (Get-Process explorer -ErrorAction SilentlyContinue) { Stop-Process -Name explorer -Force }

        if (Test-Path "$env:SYSTEMROOT\System32\OneDriveSetup.exe") {
            & "$env:SYSTEMROOT\System32\OneDriveSetup.exe" /uninstall 2>$null
        }
        if (Test-Path "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe") {
            & "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe" /uninstall 2>$null
        }

        New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive" -ItemType Directory -Force 
        Set-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1

        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force  
        Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force  
        Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force  

        New-PSDrive -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -Name "HKCR"

        mkdir -Force "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        Set-ItemProperty "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0

        mkdir -Force "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        Set-ItemProperty "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0

        Remove-PSDrive "HKCR"

        reg load "HKU\Default" "C:\Users\Default\NTUSER.DAT"
        reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f
        reg unload "HKU\Default"

        Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -Recurse -Force 

        # Restart Windows Explorer..
        if (Get-Process explorer -ErrorAction SilentlyContinue) {
            Stop-Process -Name explorer -Force
        }

        Start-Sleep -Seconds 2   # Allow time for Windows to auto-restart Explorer.exe

    }

    catch {

        Write-Warning "`n[$(Get-Timestamp)] An error occurred while trying to remove OneDrive: $($_.Exception.Message)"

    }
    
} 