# Uninstall YAML-Support
if (Get-Module -Name powershell-yaml -ListAvailable) {
    Uninstall-Module -Name powershell-yaml -Scope CurrentUser
}
# Delete Folder
if (Test-Path $configFolder -PathType Container) {
    Remove-Item -Path $configFolder -Recurse -Force
}
Pause