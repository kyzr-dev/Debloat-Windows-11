@{
    RootModule            = 'KYZR.DEBLOAT.psm1'
    ModuleVersion         = '1.3.61'
    GUID                  = '00000000-0000-0000-0000-000000000000'
    Author                = 'Brandon Kaiser'
    CompanyName           = ''
    Description           = 'A small helper module for use in debloating Windows 11 24H2 (x64)'
    PowerShellVersion     = '5.1'
    CompatiblePSEditions  = @('Desktop')
    
    FunctionsToExport     = '*'
    AliasesToExport       = '*'
    VariablesToExport     = @()
    CmdletsToExport       = @()
    RequiredModules       = @()   # add if/when you have dependencies
    PrivateData           = @{ }  # gallery metadata if you ever publish
}
