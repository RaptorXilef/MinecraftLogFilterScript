# Funktion zur Bestätigung von Aktionen mit Ja/Nein-Abfrage
function Confirm-Action {
    param (
        [string]$Message
    )
    $response = Read-Host "$Message (J/N)"
    if ($response -eq "J" -or $response -eq "j") {
        return $true
    } else {
        return $false
    }
}

# Variablen
$configFolder = "MinecraftLogFilter"


# Uninstall YAML-Support
if (Get-Module -Name powershell-yaml -ListAvailable) {
    if (Confirm-Action "Möchten Sie das Modul 'powershell-yaml', dass zum Auslesen von yml Dateien benötigt wurde wieder deinstallieren? / Do you want to uninstall the module 'powershell-yaml' that was needed to read yml files?") {
        Uninstall-Module -Name powershell-yaml -Scope CurrentUser
    }
}

# Uninstall GZ-Support
if (Get-Module -Name Microsoft.PowerShell.Archive -ListAvailable) {
    if (Confirm-Action "Möchten Sie das Modul 'Microsoft.PowerShell.Archive', dass zum Entpacken von gz-Archiv-Dateien benötigt wurde wieder deinstallieren? / Would you like to uninstall the module 'Microsoft.PowerShell.Archive', which was required for unpacking gz archive files?") {
        Uninstall-Module -Name Microsoft.PowerShell.Archive -Scope CurrentUser
    }
}

# Löschen des Ordners
if (Test-Path $configFolder -PathType Container) {
    if (Confirm-Action "Möchten Sie den Ordner $configFolder mit allen enthaltenen Dateien löschen? / Would you like to delete the $configFolder folder with all the files it contains?") {
        Remove-Item -Path $configFolder -Recurse -Force
    }
}
Pause













<#
# Uninstall YAML-Support
if (Get-Module -Name powershell-yaml -ListAvailable) {
    Uninstall-Module -Name powershell-yaml -Scope CurrentUser
}
# Uninstall GZ-Support
if (Get-Module -Name Microsoft.PowerShell.Archive -ListAvailable) {
    Uninstall-Module -Name Microsoft.PowerShell.Archive -Scope CurrentUser
}
# Delete Folder
if (Test-Path $configFolder -PathType Container) {
    Remove-Item -Path $configFolder -Recurse -Force
}
Pause
#>