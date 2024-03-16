Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Funktion zur Bestätigung von Aktionen mit Ja/Nein-Abfrage
function Confirm-Action {
    param (
        [string]$Message
    )

    $ConfirmationResult = [System.Windows.Forms.MessageBox]::Show($Message, "Entfernen bestätien", "YesNo")
    return ($ConfirmationResult -eq "Yes")
}

function Confirm-Uninstall {
    param (
        [string]$Message
    )

    $ConfirmationResult = [System.Windows.Forms.MessageBox]::Show($Message, "Deinstallation abgeschlossen", "OK")
    return ($ConfirmationResult -eq "Yes")
}


# Variablen
$configFolder = "MinecraftLogFilter"

# Funktion zum Deinstallieren eines Moduls
function Uninstall-ModuleFunction {
    param (
        [string]$ModuleName
    )
    
    try {
        Uninstall-Module -Name $ModuleName -Force -ErrorAction Stop
        Confirm-Uninstall "Die deinstallation von $ModuleName wurde abgeschlossen."
        return $true
    } catch {
        Write-Host "Fehler beim Deinstallieren des Moduls '$ModuleName': $_"
        return $false
    }
}



# Laden des Inhalts der XAML-Datei
$XamlContent = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="PowerShell Module Uninstaller" Height="120" Width="400">
    <StackPanel Margin="10">
        <Button Name="yamlButton" Content="powershell-yaml deinstallieren"/>
        <Button Name="archiveButton" Content="Microsoft.PowerShell.Archive deinstallieren"/>
        <Button Name="folderButton" Content="Ordner löschen"/>
    </StackPanel>
</Window>
"@

# Erstellen des Fensters
$Window = [Windows.Markup.XamlReader]::Parse($XamlContent)

# Ereignishandler für die Schaltflächen
$Window.FindName("yamlButton").Add_Click({
    if (Confirm-Action "Möchten Sie das Modul 'powershell-yaml' wirklich deinstallieren?") {
        $ModuleName = "powershell-yaml"
        Uninstall-ModuleFunction -ModuleName $ModuleName
    }
})

$Window.FindName("archiveButton").Add_Click({
    if (Confirm-Action "Möchten Sie das Modul 'Microsoft.PowerShell.Archive' wirklich deinstallieren?") {
        $ModuleName = "Microsoft.PowerShell.Archive"
        Uninstall-ModuleFunction -ModuleName $ModuleName
    }
})

$Window.FindName("folderButton").Add_Click({
    if (Confirm-Action "Möchten Sie den Ordner $configFolder mit allen enthaltenen Dateien wirklich löschen? Damit werden auch alle enthaltenen Logdateien entfernt!") {
        Remove-Item -Path $configFolder -Recurse -Force
    }
})

# Anzeigen des Fensters
$Window.ShowDialog() | Out-Null
