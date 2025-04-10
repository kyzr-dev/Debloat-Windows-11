function New-MessageBox {
    param (
        [parameter(Mandatory=$true)][string] $Message,
        [parameter(Mandatory=$true)][string] $WindowTitle,
        [parameter(Mandatory=$true)][string] $Buttons,
        [string] $Icon = "Information",
        [bool]$AlwaysOnTop=$true
        )

	Add-Type -AssemblyName System.Windows.Forms
    
	$form = New-Object Windows.Forms.Form
	$form.TopMost = $AlwaysOnTop
	$form.StartPosition = 'CenterScreen'
	$form.ShowInTaskbar = $false
	$form.WindowState = 'Minimized'
	$form.Show()
	$form.Hide()
	
	return [System.Windows.Forms.MessageBox]::Show($form, $Message, $WindowTitle, $Buttons, $Icon)
}