$currentVersion = "v0.0.2"
<#
.SYNOPSIS
Das Minecraft Log Filter Script ist ein PowerShell-Skript, das die Filterung und Verarbeitung von Minecraft-Server-Logdateien automatisiert.

.DESCRIPTION
Dieses Skript ermöglicht es Benutzern, Logdateien zu analysieren, bestimmte Ereignisse zu extrahieren und diese basierend auf benutzerdefinierten Filterkriterien in separate Dateien zu organisieren. Es unterstützt mehrere Sprachen, darunter Englisch und Deutsch, um eine breite Benutzerbasis anzusprechen. Das Skript automatisiert den gesamten Prozess vom Lesen der Konfigurationsdatei bis hin zum Filtern der Logs und der Organisation der Ergebnisse in separate Ordner. Die Benutzeroberfläche ist intuitiv gestaltet, und das Skript führt den Benutzer durch den Konfigurationsprozess.

.PARAMETER None
Dieses Skript erwartet keine Parameter.

.EXAMPLE
.\MinecraftLogFilterScript.ps1
Führt das Skript aus, um die Minecraft-Server-Logdateien zu filtern und zu verarbeiten.

.NOTES
Projektname: MinecraftLogFilterScript
Version: 1.0
Autor: RaptorXilef
GitHub: https://github.com/raptorxilef/MinecraftLogFilterScript
Lizenz: GNU GENERAL PUBLIC LICENSE - Version 3, 29 June 2007
#>
# ToDo 1. Mit "Visual Studio Code" gefundene Fehler beseitigen
# ToDo 2. Code nach konvention strukturieren und in Formeln aufgliedern
# ToDo 3. NAch update suchen, bevor eine config.yml existiert, wenn existiert erst:
# ToDo     Updatefunktion am Ende des Skripts ausführen, nach der Ausgabe der gefilterten Daten
# Todo 4. Funktion einbauen, in Config die Updates zu deaktivieren. 

<#
Beispielshema:
function CheckFileAndExecute {
    param (
        [string]$filePath
    )

    # Überprüfen, ob die Datei existiert
    if (Test-Path $filePath -PathType Leaf) {
        $variable = 0
    } else {
        $variable = 1
    }

    # Restlicher Code, der unabhängig vom Ergebnis der Dateiüberprüfung ausgeführt wird
    # Hier können Sie den restlichen Code einfügen, der unabhängig vom Dateiexistenzstatus ausgeführt werden soll
    Write-Host "Variable: $variable"
    Write-Host "Weiterer Code, der immer ausgeführt wird"
}

# Beispielaufruf der Funktion
CheckFileAndExecute -filePath "C:\Pfad\Zur\Datei.txt"
#>


function CheckIfUpdateIsAvailable {
    param (
        [string]$currentVersion = "0.0.1-stabile", # <----------- VERSION
        [string]$repoOwner = "RaptorXilef",
        [string]$repoName = "MinecraftLogFilterScript"
    )

    # Definition der Funktion Get-LatestVersionFromGitHub zum abrufen der Versionsnummer aus tag_name von GitHub # Definition of the Get-LatestVersionFromGitHub function to retrieve the version number from tag_name from GitHub
    function Get-LatestVersionFromGitHub($releaseUrlApi) {
        # Variablen
        $releaseUrlApi = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
        try {
            $response = Invoke-RestMethod -Uri $releaseUrlApi -Method Get
            $latestVersion = $response.tag_name
            return $latestVersion
        }
        catch {
            Write-Host "GitHub API von MinecraftLogFilterScript nicht erreichbar." -ForegroundColor Red
            Write-Host "Es konnte nicht geprüft werden ob ein Update verfügbar ist." -ForegroundColor Red
            return $null
        }
    }

    # Funktion zur Trennung von Versionsnummer und Suffix # Function for separating version number and suffix
    function Split-Version {
        param (
            [string]$version
        )

        if ($version) {
            # Trennen der Version und des Suffix durch den Bindestrich # Separate the version and the suffix with the hyphen
            $version, $versionSurfix = $version -split "-"

            # Rückgabe der Ergebnisse # Return of the results
            return ,$version, $versionSurfix
        }
    }

    # Funktion zur Entfernung eines vorstehenden "v" # Function for removing a protruding "v"
    function Remove-vFromVersion {
        param (
            [string]$version
        )

        if ($version) {
#            Write-Host "String mit 'v': $version"
            # Überprüfen, ob der String mit "v" beginnt # Check whether the string begins with "v"
            if ($version.StartsWith("v")) {
                # Entfernen des "v" vom Anfang des Strings # Remove the "v" from the beginning of the string
                $version = $version.Substring(1)
#                Write-Host "String ohne 'v': $version"
            }

            # Rückgabe der Ergebnisse # Return of the results
            return $version
        }
    }

    # Funktion zur Konvertierung ins System.Version Format # Function for converting to System.version format
    function ConvertTo-SystemVersion {
        param (
            [string]$version
        )

        if ($version) {
            # Konvertieren des $version in Version # Convert the $version to version
            $version = [Version]$version

            # Rückgabe der Ergebnisse # Return of the results
            return $version
        }
    }

    # Funktion um jeder Pre-Releases-Bezeichnung einen Int-Wert zu zu ordnen # Function to assign an Int value to each pre-release designation
    function Test-IsVersionsSurfixChange {
        param (
            [string]$versionSurfix
        )
        if ($versionSurfix) {
            if ($versionSurfix -eq "alpha") {
                $versionSurfixValueAsNumber = [Int32]"1"
            } elseif ($versionSurfix -eq "beta") {
                $versionSurfixValueAsNumber = [Int32]"2"
            } elseif ($versionSurfix -eq "rc") {
                $versionSurfixValueAsNumber = [Int32]"3"
            } elseif ($versionSurfix -eq "release_candidate") {
                $versionSurfixValueAsNumber = [Int32]"3"
            } elseif ($versionSurfix -eq "stabile") {
                $versionSurfixValueAsNumber = [Int32]"4"
            } elseif ($versionSurfix -eq "stabile_version") {
                $versionSurfixValueAsNumber = [Int32]"4"
            } elseif ($versionSurfix -eq "") {
                $versionSurfixValueAsNumber = [Int32]"5"
            } else {
                $versionSurfixValueAsNumber = [Int32]"0"
            }
        } else {
            $versionSurfixValueAsNumber = [Int32]"5"
        }
        return $versionSurfixValueAsNumber
    }

    # Definition der Funktion CheckForUpdate zum Ausgeben, ob ein Update verfügbar ist, oder nicht. # Definition of the CheckForUpdate function to output whether an update is available or not.
    function Test-UpdateAvailableWithoutConfig($currentVersion, $lastVersion, $repoOwner, $repoName) {
        $releaseUrl = "https://github.com/$repoOwner/$repoName/releases/latest"
        if ($lastVersion) {
            if (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -eq $lastVersionSurfixValueAsNumber) -or (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -gt $lastVersionSurfixValueAsNumber) -or ($currentVersion -gt $lastVersion))) {
                Write-Host "Info" -ForegroundColor White
                Write-Host ""
                Write-Host "[DE] Die installierte Version: $currentVersion ($currentVersionSurfix) ist auf dem neuesten Stand." -ForegroundColor Green
                Write-Host "[EN] The installed version: $currentVersion ($currentVersionSurfix) is up to date." -ForegroundColor Green
                Write-Host ""
            
            } elseif (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -lt $lastVersionSurfixValueAsNumber) -or ($currentVersion -lt $lastVersion)) {
                Write-Host "Info" -ForegroundColor White
                Write-Host ""
                Write-Host "[DE] Es ist ein Update verfügbar!" -ForegroundColor Yellow
                Write-Host "[DE] Installierte Version: $currentVersion ($currentVersionSurfix), Neueste Version: $lastVersion ($lastVersionSurfix)"
                Write-Host "[DE] Möchten Sie die Downloadseite zur letzten Version in Ihrem Browser öffnen? (J/N)"
                Write-Host ""
                Write-Host "[EN] An update is available!" -ForegroundColor Yellow
                Write-Host "[EN] Installed version: $currentVersion ($currentVersionSurfix), Latest version: $lastVersion ($lastVersionSurfix)"
                $answer = Read-Host "Would you like to open the download page for the latest version in your browser? (Y/N)"

                if ($answer -eq "J" -or $answer -eq "j") {
                    Start-Process $releaseUrl
                }
                else {
                    Write-Host "Update" -ForegroundColor White
                    Write-Host ""
                    Write-Host "[DE] Öffnen Sie die Seite $releaseUrl, um das neueste Update anzuzeigen."
                    Write-Host "[DE] Sie können auch die Suche nach Updates in der $configFile deaktivieren."
                    Write-Host "[DE] Drücken Sie eine beliebige Taste, um fortzufahren ..."
                    Write-Host ""
                    Write-Host "[EN] Open the $releaseUrl page to display the latest update."
                    Write-Host "[EN] You can also deactivate the search for updates in the $configFile."
                    Read-Host "[EN] Press any button to continue ..."
                }
            
            }
        }
    }

    # ToDo Übersetzungen in lang-?.yml einbauen
    # Definition der Funktion CheckForUpdate zum Ausgeben, ob ein Update verfügbar ist, oder nicht. # Definition of the CheckForUpdate function to output whether an update is available or not.
    function Test-UpdateAvailableWithConfig($currentVersion, $lastVersion, $repoOwner, $repoName) {
        $releaseUrl = "https://github.com/$repoOwner/$repoName/releases/latest"
        if ($lastVersion) {
            if (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -eq $lastVersionSurfixValueAsNumber) -or (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -gt $lastVersionSurfixValueAsNumber) -or ($currentVersion -gt $lastVersion))) {
                Write-Host "The installed version: $currentVersion ($currentVersionSurfix) is up to date." -ForegroundColor Green
            
            } elseif (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -lt $lastVersionSurfixValueAsNumber) -or ($currentVersion -lt $lastVersion)) {
                Write-Host "An update is available!" -ForegroundColor Yellow
                Write-Host "Installed version: $currentVersion ($currentVersionSurfix), Latest version: $lastVersion ($lastVersionSurfix)"
                $answer = Read-Host "Would you like to open the download page for the latest version in your browser? (Y/N)"

                if ($answer -eq "J" -or $answer -eq "j" -or $answer -eq "Y" -or $answer -eq "y") {
                    Start-Process $releaseUrl
                }
                else {
                    Write-Host "Open the $releaseUrl page to display the latest update."
                    Write-Host "You can also deactivate the search for updates in the $configFile."
                    Read-Host "Press any button to continue ..."
                }
            
            }
        }
    }




    # Aufruf der Funktion Get-LatestVersionFromGitHub # Calling the Get-LatestVersionFromGitHub function
    $lastVersion = Get-LatestVersionFromGitHub $releaseUrlApi

    # Trennung von Versionsnummer und Suffix für aktuelle und letzte Version # Separation of version number and suffix for current and last version
    $currentVersion, $currentVersionSurfix = Split-Version -version $currentVersion
    $lastVersion, $lastVersionSurfix = Split-Version -version $lastVersion

    # Setzt die Versionsbezeichnung auf stabile wenn diese nicht gesetzt wurde # Sets the version designation to stabile if this has not been set
    if ($currentVersionSurfix) {} else {$currentVersionSurfix = "stabile"}
    if ($lastVersionSurfix) {} else {$lastVersionSurfix = "stabile"}

    # Entfernen des "v" vom Anfang des Strings, wenn es existiert # Remove the "v" from the beginning of the string if it exists
    $currentVersion = Remove-vFromVersion -version $currentVersion
    $lastVersion = Remove-vFromVersion -version $lastVersion

    # Konvertierung von $currentVersion von String in Version # Conversion of $currentVersion from string to version
    $currentVersion = ConvertTo-SystemVersion -version $currentVersion
    $lastVersion = ConvertTo-SystemVersion -version $lastVersion

    # Test-Ausgabe der aufgetrennten Versionen # Test-output of the split versions
#    Write-Host "Aktuelle Version: $currentVersion ($currentVersionSurfix)"
#    Write-Host "Neueste Version: $lastVersion ($lastVersionSurfix)"

    # Version-Surfix in nummerischen Wert umwandeln # Convert version surfix to numerical value
    $currentVersionSurfixValueAsNumber = Test-IsVersionsSurfixChange -versionSurfix $currentVersionSurfix
    $lastVersionSurfixValueAsNumber = Test-IsVersionsSurfixChange -versionSurfix $lastVersionSurfix

    if (-not (Test-Path $configFile -PathType Leaf)) {
        # Aufruf der Funktion CheckForUpdate
        Test-UpdateAvailableWithoutConfig $currentVersion $lastVersion $repoOwner $repoName
    } else {
        # Aufruf der Funktion CheckForUpdate
        Test-UpdateAvailableWithConfig $currentVersion $lastVersion $repoOwner $repoName
    }


}


# Variablen
    # Pfad zum Skriptordner
    $configFolder = "MinecraftLogFilter\"
    # Pfad zur Konfigurationsdatei
    $configFile = $configFolder + "config.yml"
    # Pfad zur Sprachkonfigurationsdatei für Deutsch
    $langDEFile = $configFolder + "lang-de.yml"
    # Pfad zur Sprachkonfigurationsdatei für Englisch
    $langENFile = $configFolder + "lang-en.yml"

    # Versionsvariablen für die Konfigurationsdatei und die Sprachkonfigurationsdateien
    $configFileVersion = "1"
    $langDEFileVersion = "1"
    $langENFileVersion = "1"

# Abrufen der Funktionen

CheckIfUpdateIsAvailable

PAUSE





    # Prüfen, ob die Config-Datei existiert, wenn nicht, prüfte auf Updates, bevor der restliche Code ausgeführt wird. 
#    if (-not (Test-Path $configFile -PathType Leaf)) {
        


#    }

































































<#


# ! Skript von Version 0.0.1
# ToDo Skript neu aufbauen, nach den neu erlernten konventionen: erst Funktionen definieren, dann Variablen laden, dann Funktionen ausführen. Nach diesem Shema ändern!





# Liste der verfügbaren Sprachen
$availableLanguages = @("de", "en")

# Überprüfen, ob das Modul powershell-yaml installiert ist, und es installieren, wenn nicht
if (-not (Get-Module -Name powershell-yaml -ListAvailable)) {
    Write-Host "[EN] The module 'powershell-yaml' is needed to read the config.yml, which contains the filter settings. It will now be installed..." -ForegroundColor Yellow
    Write-Host "[DE] Das Modul 'powershell-yaml' wird benötigt um die config.yml zu lesen, welche die Filtereinstellungen enthält. Es wird jetzt installiert..." -ForegroundColor Yellow
    Install-Module -Name powershell-yaml -Scope CurrentUser -Force
    Import-Module -Name powershell-yaml
}

# Importieren des Moduls powershell-yaml
Import-Module -Name powershell-yaml


# Prüfen, ob $configFolder existiert
if (-not (Test-Path $configFolder -PathType Container)) {
    # Erstellen des Ordners, falls er nicht existiert
    New-Item -ItemType Directory -Path $configFolder -Force | Out-Null
}

# Prüfen, ob die Sprachkonfigurationsdatei für Deutsch existiert, andernfalls erstellen
if (-not (Test-Path $langDEFile -PathType Leaf)) {
    $defaultLangDEConfig = @"
# Die Versionsnummer niemals bearbeiten!
langDEConfigVersion: "$langDEFileVersion"

# Die deutschen Texte
configCreatedMessage: "Die Konfigurationsdatei '{0}' wurde erstellt."
configEditMessage: "Bitte bearbeiten Sie diese Datei, um die Sprache, Filterbegriffe und Ordnerpfade anzupassen."
pressAnyKeyContinueMessage: "Drücken Sie eine beliebige Taste, um fortzufahren."
foldersCreatedMessage: "Es wurden Ordner erstellt:"
filesAddedMessage: "Bitte füge im Ordner {0} die zu filternde/n Log-Dateie/n ein. Fahre anschließend fort."
restartScriptMessage: "Fahre anschließend fort."
filesNotFoundMessage: "Bitte füge im Ordner {0} die zu filternde/n Log-Dateie/n ein."
processingLogsMessage: "Die Log-Dateien werden verarbeitet. Bitte habe einen Moment Geduld."
pleaseWaitMessage: "Bitte warten..."
processingFinishAMessage: "Die Verarbeitung von"
processingFinishBMessage: "war erfolgreich."
processingFinishFoundMessage: "Gefunden"
processingFinishFolderInfoMessage: "Sie finden die Filterergebnisse unter"
scriptFinishedMessage: "Sie können das Konsolenfenster nun schließen oder mit einer beliebigen Taste neu starten!"
"@
    $defaultLangDEConfig | Out-File -FilePath $langDEFile -Encoding utf8
#    Start-Sleep -Seconds 0
}

# Prüfen, ob die Sprachkonfigurationsdatei für Englisch existiert, andernfalls erstellen
if (-not (Test-Path $langENFile -PathType Leaf)) {
    $defaultLangENConfig = @"
# Never edit the version number!
langENConfigVersion: "$langENFileVersion"

# English texts here
configCreatedMessage: "The configuration file '{0}' has been created."
configEditMessage: "Please edit this file to customize the language, filter terms and folder paths."
pressAnyKeyContinueMessage: "Press any button to continue."
foldersCreatedMessage: "Folders have been created:"
filesAddedMessage: "Please add the log file(s) to be filtered in the folder {0}. Then continue."
restartScriptMessage: "Then continue."
filesNotFoundMessage: "Please add the log file/s to be filtered in the folder {0}."
processingLogsMessage: "The log files are being processed. Please be patient for a moment."
pleaseWaitMessage: "Please wait..."
processingFinishMessage: "Processing successful!"
processingResultMessage: "Result:"
processingFinishAMessage: "The processing of"
processingFinishBMessage: "was successful."
processingFinishFoundMessage: "Found"
processingFinishFolderInfoMessage: "You can find the filter results under"
scriptFinishedMessage: "You can now close the console window or restart it by pressing any key!"
"@
    $defaultLangENConfig | Out-File -FilePath $langENFile -Encoding utf8
#    Start-Sleep -Seconds 0
}

# Laden der Sprachkonfiguration für Deutsch
$langDEConfig = Get-Content $langDEFile | ConvertFrom-Yaml
# Laden der Sprachkonfiguration für Englisch
$langENConfig = Get-Content $langENFile | ConvertFrom-Yaml

# Überprüfen der Konfigurationsversionen für die Sprachdateien
if ($langDEConfig.langDEConfigVersion -ne $langDEFileVersion -or $langENConfig.langENConfigVersion -ne $langENFileVersion) {
    # Umbenennen der vorhandenen Sprachdateien mit zählenden Suffixen
    $count = 0
    while (Test-Path $langDEFile) {
        $count++
        $newName = "lang-de-old$count.yml"
        Rename-Item -Path $langDEFile -NewName $newName
    }
    $count = 0
    while (Test-Path $langENFile) {
        $count++
        $newName = "lang-en-old$count.yml"
        Rename-Item -Path $langENFile -NewName $newName
    }
    
    # Erstellen neuer Sprachdateien mit den Standardinhalten
    $defaultLangDEConfig | Out-File -FilePath $langDEFile -Encoding utf8
    $defaultLangENConfig | Out-File -FilePath $langENFile -Encoding utf8
}

# Nutzer nach Sprachwahl fragen und entsprechende Variable in der Konfigurationsdatei festlegen
if (-not (Test-Path $configFile -PathType Leaf)) {
    # Sprachauswahl abfragen und prüfen, ob die Auswahl gültig ist
    $selectedLang = $null
    do {
        Clear-Host
        Write-Host "Please select your language / Bitte wählen Sie Ihre Sprache:" -ForegroundColor Yellow
        for ($i=0; $i -lt $availableLanguages.Count; $i++) {
            Write-Host "$i. $($availableLanguages[$i])" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "Enter the number / Geben Sie die Nummer ein"
        $userInput = Read-Host "and confirm the number with Enter.  / und bestätigen Sie die Nummer mit Enter. "
        if ($userInput -ge 0 -and $userInput -lt $availableLanguages.Count) {
            $selectedLang = $availableLanguages[$userInput]
        } else {
            Write-Host "Invalid selection. / Ungültige Auswahl." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    } while (null -eq $$selectedLang)

    # Konfigurationsdatei mit ausgewählter Sprache erstellen
    $defaultConfig = @"
# Never edit the version number!
# Die Versionsnummer niemals bearbeiten!
configVersion: "$configFileVersion"

# Changes the language output in the script.
# default: "en"
# Stellt die Sprachausgabe im Skript um.
# Standard: "de"
lang: "$selectedLang"

# Folder name of the folder containing the files to be filtered.
# default: "to_filter"
# Ordnername des Ordners, welcher die zu filternden Dateien enthält.
#Standart: sourceFolder: "zu_filtern"
sourceFolder: "zu_filtern"

# Destination folder for the filtered files.
# default: "filtered"
# Zielordner für die gefilterten Dateien.
#Standart: "gefiltert"
outputFolder: "gefiltert"

# Folder for the files that have already been processed.
# default: "processed"
# Ordner für die bereits verarbeiteten Dateien.
# Standart: "verarbeitet"
processedFolder: "verarbeitet"

# Keywords that are used for filtering.
# Important! Special characters such as : ; [ ] { } " ' must not be included in the filter term!
# default: ERROR, WARN, not found, update, version, joined the game, logged in with, left the game
# Schlagwörter, nach denen gefiltert wird.
# Wichtig! Sonderzeichen wie : ; [ ] { } " ' dürfen nicht im Filterbegriff enthalten sein!
# Standart sind: ERROR, WARN, not found, update, version, joined the game, logged in with, left the game, issued server command:
keywords:
  - WARN
  - update
  - ERROR
  - not found
  - left the game
  - joined the game
  - version
  - logged in with
  - issued server command
"@
    $defaultConfig | Out-File -FilePath $configFile -Encoding utf8

# Laden der ausgewählten Sprachkonfiguration basierend auf der Sprache in der config.yml
$config = Get-Content $configFile | ConvertFrom-Yaml
$lang = $config.lang
$selectedLangConfig = if ($lang -eq "de") { $langDEConfig } else { $langENConfig }

    # Ausgabe der Meldung im Konsolenfenster
    Clear-Host
    Write-Host "$($selectedLangConfig.configCreatedMessage -f $configFile)" -ForegroundColor Yellow
    Write-Host $selectedLangConfig.configEditMessage -ForegroundColor Yellow
    Write-Host ""
    Write-Host $selectedLangConfig.pressAnyKeyContinueMessage -ForegroundColor Red
    [void][System.Console]::ReadKey() # Warten auf Tastendruck
    Clear-Host
    & $MyInvocation.MyCommand.Path # Skript erneut starten
}

# Laden der ausgewählten Sprachkonfiguration basierend auf der Sprache in der config.yml
$config = Get-Content $configFile | ConvertFrom-Yaml
$lang = $config.lang
$selectedLangConfig = if ($lang -eq "de") { $langDEConfig } else { $langENConfig }


# Laden der Konfiguration aus der Datei
$config = Get-Content $configFile | ConvertFrom-Yaml

# Festlegen der Variablen für Ordner aus der Konfiguration
$sourceFolder = $configFolder + $config.sourceFolder
$outputFolder = $configFolder + $config.outputFolder
$processedFolder = $configFolder + $config.processedFolder

# Prüfen, ob $sourceFolder existiert
if (-not (Test-Path $sourceFolder -PathType Container)) {
    # Erstellen der Ordner, falls sie nicht existieren
    New-Item -ItemType Directory -Path $sourceFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $processedFolder -Force | Out-Null

    # Ausgabe der Meldung im Konsolenfenster
    Clear-Host
    Write-Host ($selectedLangConfig.foldersCreatedMessage -f $sourceFolder) -ForegroundColor White
    Write-Host " - $sourceFolder" -ForegroundColor Green  # Diese Zeile hinzufügen
    Write-Host " - $processedFolder" -ForegroundColor Green
    Write-Host " - $outputFolder" -ForegroundColor Green
    Write-Host ""
    Write-Host "$($selectedLangConfig.filesAddedMessage -f $sourceFolder)" -ForegroundColor White
    Write-Host ""
    Write-Host $selectedLangConfig.pressAnyKeyContinueMessage -ForegroundColor Red
    [void][System.Console]::ReadKey() # Warten auf Tastendruck
    Clear-Host
    & $MyInvocation.MyCommand.Path # Skript erneut starten
} else {
    # Erfassen aller Dateien im $sourceFolder
    $sourceFiles = Get-ChildItem -Path $sourceFolder -File
    # Filtern der Dateien, um nur diejenigen mit der Endung ".log" beizubehalten
    $sourceFiles = $sourceFiles | Where-Object { $_.Extension -eq ".log" }
    if ($sourceFiles.Count -eq 0) {
        # Ausgabe der Meldung im Konsolenfenster
        Clear-Host
        Write-Host "$($selectedLangConfig.filesNotFoundMessage -f $sourceFolder)" -ForegroundColor White
        Write-Host " -> $sourceFolder" -ForegroundColor Cyan
        Write-Host ""
        Write-Host $selectedLangConfig.restartScriptMessage -ForegroundColor White
        Write-Host ""
        Write-Host $selectedLangConfig.pressAnyKeyContinueMessage -ForegroundColor Red
        [void][System.Console]::ReadKey() # Warten auf Tastendruck
        Clear-Host
        & $MyInvocation.MyCommand.Path # Skript erneut starten
    } else {
        # Prüfen, ob $outputFolder existiert
        if (-not (Test-Path $outputFolder -PathType Container)) {
            # Erstellen des Ordners, falls er nicht existiert
            New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
        }

        # Prüfen, ob $processedFolder existiert
        if (-not (Test-Path $processedFolder -PathType Container)) {
            # Erstellen des Ordners, falls er nicht existiert
            New-Item -ItemType Directory -Path $processedFolder -Force | Out-Null
        }

        # Meldung vor dem Verarbeiten der Log-Dateien anzeigen
        Clear-Host
        Write-Host $selectedLangConfig.processingLogsMessage -ForegroundColor Yellow
        Write-Host $selectedLangConfig.pleaseWaitMessage -ForegroundColor Yellow
        Write-Host ""

        # Filtervorgang für jede Logdatei durchführen
        foreach ($sourceFile in $sourceFiles) {
            # Pfad zur Log-Datei setzen
            $sourceFilePath = $sourceFile.FullName

            # Setze den Namen der Log-Datei und des Ausgabeverzeichnisses
            $sourceFileName = [System.IO.Path]::GetFileNameWithoutExtension($sourceFile.Name)

            # Setze den Filterzeitstempel neu
            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $outputDirectory = New-Item -ItemType Directory -Path "$outputFolder\$sourceFileName`_-_gefiltert_am_$timestamp" -Force

            # Initialisiere Zähler
            $counter = @{
                "ERROR" = 0
                "WARN" = 0
                "update" = 0
                "not found" = 0
                "left the game" = 0
                "joined the game" = 0
                "version" = 0
                "logged in with" = 0
            }

            # Durchführen des Filtervorgangs und Zählen der gefundenen Schlagwörter
            Get-Content $sourceFilePath | ForEach-Object -Begin {
                $lineNumber = 0
            } -Process {
                $lineNumber++
                $line = "$lineNumber`:`t$_"
                foreach ($keyword in $config.keywords) {
                    if ($_ -match $keyword) {
                        $counter[$keyword]++
                        $line | Out-File -Append "$outputDirectory\$keyword.log" -Encoding utf8
                    }
                }
            }

            # Ausgabe der verarbeiteten Dateinamen und der Anzahl der gefundenen Schlagwörter
            Write-Host "$($selectedLangConfig.processingFinishAMessage) '$($sourceFile.Name)' $($selectedLangConfig.processingFinishBMessage)" -ForegroundColor Green
            Write-Host "    $($selectedLangConfig.processingFinishFolderInfoMessage):" -ForegroundColor White
            Write-Host "     - $($processedFolder)\$($sourceFileName)" -ForegroundColor Cyan

            Write-Host "    $($selectedLangConfig.processingFinishFoundMessage):" -ForegroundColor White
            foreach ($key in $counter.Keys) {
                Write-Host "     - `"$key`": $($counter[$key])x;" -ForegroundColor Yellow
            }
            Write-Host ""

            # Verschieben der verarbeiteten Datei in den Zielordner mit Prüfung auf vorhandene Dateinamen
            $destination = "$processedFolder\$($sourceFile.Name)"
            $counterSuffix = 1
            while (Test-Path $destination) {
                $destination = "$processedFolder\$($sourceFileName)_$counterSuffix$($sourceFile.Extension)"
                $counterSuffix++
            }
            Move-Item -Path $sourceFilePath -Destination $destination -Force
        }
    }
}

# Ausgabe der Abschlussmeldung
Write-Host "" -ForegroundColor White
Write-Host $selectedLangConfig.scriptFinishedMessage -ForegroundColor Red
[void][System.Console]::ReadKey() # Warten auf Tastendruck
& $MyInvocation.MyCommand.Path # Skript erneut starten



#>