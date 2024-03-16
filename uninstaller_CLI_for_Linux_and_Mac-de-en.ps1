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
    Write-Host ""
    Write-Host "Minecraft Log Filter Uninstaller" -ForegroundColor Green
    Write-Host ""

    Write-Host "[DE] Modul 'powershell-yaml' deinstallieren?" -ForegroundColor Red
    Write-Host "[DE] Wurde zum Auslesen von yml Dateien benötigt."
    Write-Host ""
    Write-Host "[EN] Uninstall module 'powershell-yaml'?" -ForegroundColor Red
    Write-Host "[EN] Was needed to read yml files."
    Write-Host ""
    if (Confirm-Action "") {
        Uninstall-Module -Name powershell-yaml -Force
    }
}

# Uninstall GZ-Support
if (Get-Module -Name Microsoft.PowerShell.Archive -ListAvailable) {
    Write-Host ""
    Write-Host ""
    Write-Host "Minecraft Log Filter Uninstaller" -ForegroundColor Green
    Write-Host ""

    Write-Host "[DE] Modul 'Microsoft.PowerShell.Archive' deinstallieren?" -ForegroundColor Red
    Write-Host "[DE] Wurde zum Entpacken von gz-Archiv-Dateien benötigt."
    Write-Host "[DE] Achtung: Nicht empfohlen! Gehört zu den Standart-Modulen von PowerShell." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[EN] Uninstall module 'Microsoft.PowerShell.Archive'?" -ForegroundColor Red
    Write-Host "[EN] required for unpacking gz archive files."
    Write-Host "[EN] Attention: Not recommended! Belongs to the standard modules of PowerShell." -ForegroundColor Yellow
    Write-Host ""
    if (Confirm-Action "") {
        Uninstall-Module -Name Microsoft.PowerShell.Archive -Force
    }
}

# Löschen des Ordners
if (Test-Path $configFolder -PathType Container) {
    Write-Host ""
    Write-Host ""
    Write-Host "Minecraft Log Filter Uninstaller" -ForegroundColor Green
    Write-Host ""

    Write-Host "[DE] Ordner '$configFolder' löschen?" -ForegroundColor Red
    Write-Host "[DE] Achtung: Dadurch werden auch alle Einstellungen und im Ordner enthaltenen." -ForegroundColor Yellow
    Write-Host "[DE] .log und .gz Dateien gelöscht!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[EN] Uninstall '$configFolder'?" -ForegroundColor Red
    Write-Host "[EN] Attention: This will also delete all settings and the" -ForegroundColor Yellow
    Write-Host "[EN] .log and .gz files contained in the folder!" -ForegroundColor Yellow
    Write-Host ""
    if (Confirm-Action "") {
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