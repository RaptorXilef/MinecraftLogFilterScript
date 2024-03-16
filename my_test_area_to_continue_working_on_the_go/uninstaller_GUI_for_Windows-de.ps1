Add-Type -AssemblyName System.Windows.Forms

# Funktion zur Bestätigung von Aktionen mit Ja/Nein-Abfrage
function Confirm-Action {
    param (
        [string]$Message
    )
    $result = [System.Windows.Forms.MessageBox]::Show(
        $Message,
        "Bestätigung",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    return $result
}

# Variablen
$configFolder = "MinecraftLogFilter"

# Abfragen der installierten Module
$yamlModuleInstalled = (Get-Module -Name powershell-yaml -ListAvailable).Count -gt 0
#$archiveModuleInstalled = (Get-Module -Name Microsoft.PowerShell.Archive -ListAvailable).Count -gt 0

# Prüfen, ob der Ordner vorhanden ist
$folderExists = Test-Path -Path $configFolder -PathType Container

# Erstellen des Fensters
$window = New-Object System.Windows.Forms.Form
$window.Text = "Minecraft Log Filter Uninstaller"
$window.StartPosition = "CenterScreen"
$window.Size = New-Object System.Drawing.Size(550, 360)

# Hinzufügen von Steuerelementen
$label1 = New-Object System.Windows.Forms.Label
$label1.Font = new-object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$label1.Text = "Minecraft Log Filter Uninstaller"
$label1.Location = New-Object System.Drawing.Point(10, 10)
$window.Controls.Add($label1)
$label1.AutoSize = $true

# Hinzufügen von Steuerelementen
$label2 = New-Object System.Windows.Forms.Label
$label2.Text = ""
$label2.Location = New-Object System.Drawing.Point(10, 40)
$window.Controls.Add($label2)
$label2.AutoSize = $true

# Hinzufügen von Steuerelementen
$label3 = New-Object System.Windows.Forms.Label
$label3.Text = ""
$label3.Location = New-Object System.Drawing.Point(10, 70)
$window.Controls.Add($label3)
$label3.AutoSize = $true

# Hinzufügen von Steuerelementen
$label4 = New-Object System.Windows.Forms.Label
$label4.Font = new-object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$label4.Text = "Welche Elemente des Minecraft Log Filters sollen entfernt werden?"
$label4.Location = New-Object System.Drawing.Point(10, 120)
$window.Controls.Add($label4)
$label4.AutoSize = $true

$checkbox1 = New-Object System.Windows.Forms.CheckBox
$checkbox1.Text = "powershell-yaml Modul deinstallieren?"
$checkbox1.Location = New-Object System.Drawing.Point(10, 150)
$checkbox1.Checked = $yamlModuleInstalled
$window.Controls.Add($checkbox1)
$checkbox1.AutoSize = $true

$checkbox2 = New-Object System.Windows.Forms.CheckBox
$checkbox2.Text = "Microsoft.PowerShell.Archive Modul deinstallieren?"
$checkbox2.Location = New-Object System.Drawing.Point(10, 180)
$checkbox2.Checked = $archiveModuleInstalled
$window.Controls.Add($checkbox2)
$checkbox2.AutoSize = $true

# Hinzufügen von Steuerelementen
$label5 = New-Object System.Windows.Forms.Label
$label5.Font = new-object System.Drawing.Font($label5.Font.FontFamily, $label5.Font.Size, [System.Drawing.FontStyle]::Italic)
$label5.Text = "Achtung: Nicht empfohlen! Gehört zu den Standart-Modulen von PowerShell."
$label5.Location = New-Object System.Drawing.Point(40, 200)
$window.Controls.Add($label5)
$label5.AutoSize = $true

$checkbox3 = New-Object System.Windows.Forms.CheckBox
$checkbox3.Text = "Ordner '$configFolder' mit allen Inhalten löschen?"
$checkbox3.Location = New-Object System.Drawing.Point(10, 220)
$checkbox3.Checked = $folderExists
$window.Controls.Add($checkbox3)
$checkbox3.AutoSize = $true

# Hinzufügen von Steuerelementen
$label6 = New-Object System.Windows.Forms.Label
$label6.Font = new-object System.Drawing.Font($label5.Font.FontFamily, $label5.Font.Size, [System.Drawing.FontStyle]::Italic)
$label6.Text = "Achtung: Dadurch werden auch alle Einstellungen und im Ordner enthaltenen"
$label6.Location = New-Object System.Drawing.Point(40, 240)
$window.Controls.Add($label6)
$label6.AutoSize = $true

# Hinzufügen von Steuerelementen
$label7 = New-Object System.Windows.Forms.Label
$label7.Font = new-object System.Drawing.Font($label5.Font.FontFamily, $label5.Font.Size, [System.Drawing.FontStyle]::Italic)
$label7.Text = ".log und .gz Dateien gelöscht!"
$label7.Location = New-Object System.Drawing.Point(40, 260)
$window.Controls.Add($label7)
$label7.AutoSize = $true

$button = New-Object System.Windows.Forms.Button
$button.Text = "Aufräumen"
$button.Location = New-Object System.Drawing.Point(10, 290)
$button.Add_Click({
    $result = Confirm-Action "Sind Sie sicher, dass Sie fortfahren möchten?"

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        # Statusmeldung
        $label2.Font = new-object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $label2.ForeColor = [System.Drawing.Color]::Green
        $label2.Text = "Aufräumen wird ausgeführt..."
        $label3.Font = new-object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
        $label3.Text = "Bitte warten..."
        $label3.AutoSize = $true
        Start-Sleep -Seconds 2
        $window.Refresh()

        # Aktionen ausführen
        if ($checkbox1.Checked) {
            # Deinstallation des Moduls
            Uninstall-Module -Name powershell-yaml -Force
            # Prüfung, ob das Modul noch installiert ist
            $moduleIsInstalled = (Get-Module -Name powershell-yaml -ListAvailable).Count -gt 0
            if ($moduleIsInstalled) {
                $label2.Text = "Deinstallation von 'powershell-yaml' fehlgeschlagen!"
                $label2.AutoSize = $true
                Start-Sleep -Seconds 5
            } else {
                $label2.Text = "Deinstallation von 'powershell-yaml' erfolgreich!"
                $label2.AutoSize = $true
                Start-Sleep -Seconds 5
            }

        }

        if ($checkbox2.Checked) {
            Uninstall-Module -Name Microsoft.PowerShell.Archive -Force
            # Prüfung, ob das Modul noch installiert ist
            $moduleIsInstalled = (Get-Module -Name Microsoft.PowerShell.Archive -ListAvailable).Count -gt 0
            if ($moduleIsInstalled) {
                $label2.Text = "Deinstallation von 'Microsoft.PowerShell.Archive' fehlgeschlagen!"
                $label2.AutoSize = $true
                Start-Sleep -Seconds 5
            } else {
                $label2.Text = "Deinstallation von 'Microsoft.PowerShell.Archive' erfolgreich!"
                $label2.AutoSize = $true
                Start-Sleep -Seconds 5
            }
        }

        if ($checkbox3.Checked) {
            # Entfernen des Ordners
            Remove-Item -Path $configFolder -Recurse -Force

            # Prüfung, ob der Ordner noch vorhanden ist
            $folderExists = Test-Path -Path $configFolder

            if ($folderExists) {
                $label2.Font = new-object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
                $label2.ForeColor = [System.Drawing.Color]::RED
                #$label2.BackColor = [System.Drawing.Color]::DarkGray
                $label2.Text = "Löschen des Ordners '$configFolder' fehlgeschlagen!"
                $label2.AutoSize = $true
                Start-Sleep -Seconds 5
            } else {
                $label2.Font = new-object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
                $label2.ForeColor = [System.Drawing.Color]::Green
                #$labe3.BackColor = [System.Drawing.Color]::DarkGray
                $label2.Text = "Löschen des Ordners '$configFolder' erfolgreich!"
                $label2.AutoSize = $true
                Start-Sleep -Seconds 5
            }
        }

        # Abschlussmeldung
        $label2.Font = new-object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $label2.ForeColor = [System.Drawing.Color]::Green
        #$label2.BackColor = [System.Drawing.Color]::DarkGray
        $label2.Text = "Aufräumen abgeschlossen!"

        Start-Sleep -Seconds 5
        $label2.Font = new-object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $label2.ForeColor = [System.Drawing.Color]::RED
        #$label2.BackColor = [System.Drawing.Color]::DarkGray
        $label2.Text = "Minecraft Log Filter Uninstaller wird beendet!"
        Start-Sleep -Seconds 5
        $window.Close()
    } else {
        # Abbruchmeldung
        MessageBox.Show("Der Vorgang wurde abgebrochen.", "Information")
    }
})
$window.Controls.Add($button)

# Anzeigen des Fensters
$window.ShowDialog()
