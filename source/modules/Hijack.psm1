Function Get-Privilege {
  param($Privilege)
  $Definition = @'
using System;
using System.Runtime.InteropServices;
public class AdjPriv {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
    ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr rele);
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name,
    ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid {
    public int Count;
    public long Luid;
    public int Attr;
  }
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool EnablePrivilege(long processHandle, string privilege) {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = new IntPtr(processHandle);
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
      ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_ENABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero,
      IntPtr.Zero);
    return retVal;
  }
}
'@
  $ProcessHandle = (Get-Process -id $pid).Handle
  $type = Add-Type $definition -PassThru
  $type[0]::EnablePrivilege($processHandle, $Privilege)
}

function Hijack-RegKey($LiteralKey) {  # Function currently only works with HKEY_CLASSES_ROOT, HKEY_CURRENT_USER, and HKEY_LOCAL_MACHINE roots. Planning to add more.
	$key = $null
	
	do {} until (Get-Privilege SeTakeOwnershipPrivilege)

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

function Hijack-Path([string]$FilePath) {
	$path = Get-Item $FilePath
    $username = [Security.Principal.WindowsIdentity]::GetCurrent().Name
	$currentUser = [Security.Principal.NTAccount]$username
    $adminSecGroup = [Security.Principal.NTAccount]'Administrators'
    $systemSecGroup = [Security.Principal.NTAccount]'SYSTEM'
	
    $acl = $path.GetAccessControl()
    $acl.SetOwner($currentUser)

    # Uncomment the next 2 lines if you want to completely remove all existing UAC rules before adding the new ones. Only Administrators and SYSTEM will have access.
    #$acl.SetAccessRuleProtection($True, $False)
    #$acl.Access | % {$acl.RemoveAccessRule($_)}

	$path.SetAccessControl($acl)

    switch ((Get-Item -Path $path).PSIsContainer){
        $true {
	        $rules = @(
		        New-Object System.Security.AccessControl.FileSystemAccessRule($systemSecGroup, 'FullControl', 'ObjectInherit, ContainerInherit', 'None', 'Allow');
		        New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, 'FullControl', 'ObjectInherit, ContainerInherit', 'None', 'Allow');
		        New-Object System.Security.AccessControl.FileSystemAccessRule($adminSecGroup, 'FullControl', 'ObjectInherit, ContainerInherit', 'None', 'Allow');
	        ) | ForEach-Object { $acl.AddAccessRule($_) }
        }

        $false {
            $rules = @(
		        New-Object System.Security.AccessControl.FileSystemAccessRule($systemSecGroup, 'FullControl', "None", "None", "Allow");
		        New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, 'FullControl', "None", "None", "Allow");
		        New-Object System.Security.AccessControl.FileSystemAccessRule($adminSecGroup, 'FullControl', "None", "None", "Allow");
	        ) | ForEach-Object { $acl.AddAccessRule($_) }
            }
    }
	
	$path.SetAccessControl($acl)
}
