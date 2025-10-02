function Unlock-RegACL {
	param (
		[parameter(Mandatory=$true)][string] $LiteralKey,
		[parameter(Mandatory=$false)][System.Security.Principal.NTAccount] $Owner,
		[switch] $Recurse
	)

	$ErrorActionPreference = 'Stop'

	do {} until ( Add-Privilege SeTakeOwnershipPrivilege )

	# Normalize common prefixes like 'Registry::'
	$san = $LiteralKey.Trim()
	$san = $san -replace '^Registry::', ''
	$san = $san -replace '^Registry:\\', ''
	$san = $san -replace '^Registry:', ''

	# Split into root and subpath
	$parts = $san -split '\\', 2
	$root  = $parts[0].TrimEnd(':').ToUpperInvariant()
	$sub   = if ($parts.Count -gt 1) { $parts[1] } else { '' }

	# Map to RegistryHive enum member names
	switch ($root) {
	'HKLM'               { $hiveName = 'LocalMachine' }
	'HKEY_LOCAL_MACHINE' { $hiveName = 'LocalMachine' }
	'HKCU'               { $hiveName = 'CurrentUser'  }
	'HKEY_CURRENT_USER'  { $hiveName = 'CurrentUser'  }
	'HKCR'               { $hiveName = 'ClassesRoot'  }
	'HKEY_CLASSES_ROOT'  { $hiveName = 'ClassesRoot'  }
	'HKU'                { $hiveName = 'Users'        }
	'HKEY_USERS'         { $hiveName = 'Users'        }
	'HKCC'               { $hiveName = 'CurrentConfig'}
	'HKEY_CURRENT_CONFIG'{ $hiveName = 'CurrentConfig'}
	default { throw "Unrecognized hive root '$root' in '$LiteralKey'." }
	}

	$hiveEnum = [Microsoft.Win32.RegistryHive]::$hiveName
	$baseKey  = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
				$hiveEnum, [Microsoft.Win32.RegistryView]::Default)

	$registryKey = if ($sub) {
	$baseKey.OpenSubKey(
		$sub,
		[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
		[System.Security.AccessControl.RegistryRights]::TakeOwnership
	)
	} else {
		$baseKey
	}

	if (-not $registryKey) { throw "Registry key not found or inaccessible: $LiteralKey" }


	# Security objects
	$systemSecGroup = [Security.Principal.NTAccount]'SYSTEM'
	$administratorsSecGroup = [Security.Principal.NTAccount]'Administrators'

	try {
		
		# Load ACL
		$acl = $registryKey.GetAccessControl()
		
		# Change owner
		if ($null -eq $Owner){

			$acl.SetOwner($administratorsSecGroup)

		} else {

			try {
				
				do {} until ( Add-Privilege SeRestorePrivilege )

				$sid = $Owner.Translate([System.Security.Principal.SecurityIdentifier])

				$acl.SetOwner($sid)

			}
			catch {
				$ERR_SET_OWNER = "An error occurred while attempting to change the owner of a registry key: $($_.Exception.Message)"
				throw $ERR_SET_OWNER
			}

		}
		
		# Commit owner changes
		$registryKey.SetAccessControl($acl)
		
		# Define new rules
		$rules = @(
			New-Object System.Security.AccessControl.RegistryAccessRule($administratorsSecGroup, "FullControl",'ObjectInherit,ContainerInherit', 'None', 'Allow');
			New-Object System.Security.AccessControl.RegistryAccessRule($systemSecGroup, "FullControl",'ObjectInherit,ContainerInherit', 'None', 'Allow')
		)
		
		# Inject new rules
		$rules | ForEach-Object { $acl.AddAccessRule($_) }
		$registryKey.SetAccessControl($acl)
		
		Write-Timestamp "Successfully updated security and ownership settings on reg key: $LiteralKey"

	} catch {

		$ERR_REG_ACL = "`n[$(Get-Timestamp)] Unable to change security settings for $LiteralKey : $($_.Exception.Message)"
		throw $ERR_REG_ACL

	} finally {

		$registryKey.Close()

	}

	if ($Recurse){

		try {

			$children = Get-ChildItem -Path $lookupPath -ErrorAction SilentlyContinue

			if (-not $children) { return }

			foreach ($child in $children) {
				Write-Timestamp "Attempting to access ACL on a child reg key: '$($child.Name)'"
				Unlock-RegACL -LiteralKey $child.Name -Recurse

			}

		} catch {

			$ERR_REG_ACL = "Error enumerating subkeys: $($_.Exception.Message)"
			throw $ERR_REG_ACL

		}
	}
}