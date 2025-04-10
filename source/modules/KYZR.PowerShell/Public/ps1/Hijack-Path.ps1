function Hijack-Path {
	param (
		[Parameter(Mandatory=$true)][string]$FilePath,
		[Parameter(Mandatory=$false)]$RemoveACL=$null # boolean value re: whether to remove existing UAC rules but should be init as #null
	) 
	
    begin {
        $ERR_INVALID_PATH =  "`'$FilePath`' is not a valid path. Aborting attempt to edit security properties."

        if (-not (Test-Path $FilePath)) {
            throw $ERR_INVALID_PATH
            return
        }
        
        $canonicalPath = Format-PathCase $FilePath
        $username = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        $currentUser = [Security.Principal.NTAccount]$username
        $adminSecGroup = [Security.Principal.NTAccount]'Administrators'
        $systemSecGroup = [Security.Principal.NTAccount]'SYSTEM'
        $msgBoxArguments = @{
            Message = "Attempting to gain access to `'$canonicalPath`'`n`nDo you want to remove existing UAC rules before taking control of the path?"
            WindowTitle = 'KYZR - Hijack File Path'
            Buttons = 'YesNoCancel'
            Icon = 'Question'
        
        }
    }

    process {
        do {} until (Add-Privilege SeTakeOwnershipPrivilege)
        $path = Get-Item $FilePath
        $acl = $path.GetAccessControl()
        $acl.SetOwner($currentUser)
        $path.SetAccessControl($acl)

        $successAddon = " "
        
        if ($null -eq $RemoveACL){ # If not specified, prompt user to make a choice via MessageBox
            $removeACLPrompt = New-MessageBox @msgBoxArguments
            switch ($removeACLPrompt) {
                'Yes' {
                    try {
                        $acl.SetAccessRuleProtection($True, $False) ; $acl.Access | ForEach-Object {$acl.RemoveAccessRule($_)}
                        $RemoveACL = $true
                        $successAddon = "after removing pre-existing rules."
                    } catch { 
                        Write-Output "[$(Get-Timestamp)] ERROR - Failed to remove ACL rules from $FilePath : $_"
                        Write-Output "`nAttempt to add new ACL rule will continue..`n"
                        $successAddon = "but failed to remove pre-existing rules."
                    }
                }
                'No' { $successAddon = "without removing any pre-existing rules" }
                'Cancel' { exit }
            }
        } 
        else { # If specified, proceed with specification
            switch ($RemoveACL){
                $true {
                    try {
                        $acl.SetAccessRuleProtection($True, $False) ; $acl.Access | ForEach-Object {$acl.RemoveAccessRule($_)}
                        $successAddon = "after removing pre-existing rules."
                    } catch { 
                        Write-Output "[$(Get-Timestamp)] ERROR - Failed to remove ACL rules from $FilePath : $_"
                        Write-Output "`nAttempt to add new ACL rule will continue..`n"
                        $successAddon = "but failed to remove pre-existing rules."
                    }
                }
                $false { $successAddon = "without removing any pre-existing rules" }
            }
        }
        
        $path.SetAccessControl($acl)

        switch ($path.PSIsContainer){
            $true {
                $rules = @(
                    New-Object System.Security.AccessControl.FileSystemAccessRule($systemSecGroup, 'FullControl', 'ObjectInherit, ContainerInherit', 'None', 'Allow');
                    New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, 'FullControl', 'ObjectInherit, ContainerInherit', 'None', 'Allow');
                    New-Object System.Security.AccessControl.FileSystemAccessRule($adminSecGroup, 'FullControl', 'ObjectInherit, ContainerInherit', 'None', 'Allow');
                )
                
                $rules | ForEach-Object { $acl.AddAccessRule($_) }
                try {
                    $path.SetAccessControl($acl)
                    Write-Output "Successfully modified the ACL of `"$canonicalPath`" $successAddon `n"
                    foreach ($child in Get-ChildItem -Path $canonicalPath){
                        Hijack-Path $child.FullName $RemoveACL
                    }
                } catch {
                    Write-Output "[$(Get-Timestamp)] ERROR - Failed to add new ACL rule(s) to $canonicalPath : $_"
                }

            }

            $false {
                $rules = @(
                    New-Object System.Security.AccessControl.FileSystemAccessRule($systemSecGroup, 'FullControl', "None", "None", "Allow");
                    New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, 'FullControl', "None", "None", "Allow");
                    New-Object System.Security.AccessControl.FileSystemAccessRule($adminSecGroup, 'FullControl', "None", "None", "Allow");
                ) 
                
                $rules | ForEach-Object { $acl.AddAccessRule($_) }
                try {
                    $path.SetAccessControl($acl)
                    Write-Output "`n[$(Get-Timestamp)] Successfully modified the ACL of `"$canonicalPath`" $successAddon `n"
                } catch {
                    Write-Output "[$(Get-Timestamp)] ERROR - Failed to add new ACL rule(s) to $canonicalPath : $_"
                }
            }
        }
    }

    end { 
        
    }
}