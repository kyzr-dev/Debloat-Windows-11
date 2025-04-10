function Hijack-RegKey { 
	param (
		[parameter(Mandatory=$true)][string] $LiteralKey
	)

# Function currently only works on keys with HKEY_CLASSES_ROOT, HKEY_CURRENT_USER, and HKEY_LOCAL_MACHINE roots. Planning to add support for more.
	$key = $null
	
	do {} until (Add-Privilege SeTakeOwnershipPrivilege)

        switch ($LiteralKey.split('\')[0]) {
        "HKEY_CLASSES_ROOT" {
            $reg = [Microsoft.Win32.Registry]::ClassesRoot
            $key = $LiteralKey.substring(18)
        }
        "HKEY_CURRENT_USER" {
            $reg = [Microsoft.Win32.Registry]::CurrentUser
            $key = $LiteralKey.substring(18)
        }
        "HKEY_LOCAL_MACHINE" {
            $reg = [Microsoft.Win32.Registry]::LocalMachine
            $key = $LiteralKey.substring(19)
        }
    }

    $key = $reg.OpenSubKey($key, 'ReadWriteSubTree', 'TakeOwnership')
    $adminSecGroup = [Security.Principal.NTAccount]'Administrators'
    $acl = $key.GetAccessControl()

    # Take Ownership
    $acl.SetOwner($adminSecGroup)
    $key.SetAccessControl($acl)

    # Grant Full Control
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($adminSecGroup, "FullControl",'ObjectInherit, ContainerInherit', 'None', 'Allow')
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
}
