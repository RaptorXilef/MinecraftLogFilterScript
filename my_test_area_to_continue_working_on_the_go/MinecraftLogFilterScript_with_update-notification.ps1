# Projektname: MinecraftLogFilterScript

# Autor: RaptorXilef 
# GitHub: https://github.com/RaptorXilef/MinecraftLogFilterScript
# REM Lizens: GNU GENERAL PUBLIC LICENSE - Version 3, 29 June 2007

# ! Update-Skript aus den Tests
# Definition der Funktion Get-LatestVersionFromGitHub
function Get-LatestVersionFromGitHub($releaseUrlApi) {
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

# Definition der Funktion CheckForUpdate
function CheckForUpdate($installierteVersion, $neuesteVersion, $repoOwner, $repoName, $releaseUrl) {
    if ($neuesteVersion) {
        if ($neuesteVersion -gt $installierteVersion) {
            Write-Host "Es ist ein Update verfügbar!"
            Write-Host "Installierte Version: $installierteVersion, Neueste Version: $neuesteVersion"
            Write-Host "GitHub Projektseite: https://github.com/$repoOwner/$repoName"
            
            Write-Host "Neuestes Release: $releaseUrl"
            $antwort = Read-Host "Möchten Sie die Seite zum Release öffnen? (J/N)"
            if ($antwort -eq "J" -or $antwort -eq "j") {
                Start-Process $releaseUrl
            }
            else {
                Write-Host "Öffnen Sie die Seite $releaseUrl, um das neueste Release anzuzeigen."
                Read-Host "Drücken Sie eine beliebige Taste, um fortzufahren ..."
            }
        }
        else {
            Write-Host "Die installierte Version ($installierteVersion) ist auf dem neuesten Stand."
            Read-Host "Drücken Sie eine beliebige Taste, um fortzufahren ..."
        }
    }
}

# Variablen
$installierteVersion = "v0.0.9"
$repoOwner = "RaptorXilef"
$repoName = "MinecraftLogFilterScript"
$releaseUrlApi = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
$releaseUrl = "https://github.com/$repoOwner/$repoName/releases/latest"

# Aufruf der Funktion Get-LatestVersionFromGitHub
$neuesteVersion = Get-LatestVersionFromGitHub $releaseUrlApi

# Aufruf der Funktion CheckForUpdate
CheckForUpdate $installierteVersion $neuesteVersion $repoOwner $repoName $releaseUrl

# Hier kommt dann der restliche Teil des Skripts
Read-Host "Drücken Sie eine beliebige Taste, um fortzufahren ..."

# ! Ende Update-Skript aus den Tests













# ! Skript von Version 0.0.1
# ToDo Skript neu aufbauen, nach den neu erlernten konventionen: erst Funktionen definieren, dann Variablen laden, dann Funktionen ausführen. Nach diesem Shema ändern!

# Aktuelle Skriptversion
$minecraftLogFilterScriptVersion = "0.0.1"

# Pfad zur Konfigurationsdatei
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
        cls
        Write-Host "Please select your language / Bitte wählen Sie Ihre Sprache:" -ForegroundColor Yellow
        for ($i=0; $i -lt $availableLanguages.Count; $i++) {
            Write-Host "$i. $($availableLanguages[$i])" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "Enter the number / Geben Sie die Nummer ein"
        $input = Read-Host "and confirm the number with Enter.  / und bestätigen Sie die Nummer mit Enter. "
        if ($input -ge 0 -and $input -lt $availableLanguages.Count) {
            $selectedLang = $availableLanguages[$input]
        } else {
            Write-Host "Invalid selection. / Ungültige Auswahl." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    } while ($selectedLang -eq $null)

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
    cls
    Write-Host "$($selectedLangConfig.configCreatedMessage -f $configFile)" -ForegroundColor Yellow
    Write-Host $selectedLangConfig.configEditMessage -ForegroundColor Yellow
    Write-Host ""
    Write-Host $selectedLangConfig.pressAnyKeyContinueMessage -ForegroundColor Red
    [void][System.Console]::ReadKey() # Warten auf Tastendruck
    cls
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
    cls
    Write-Host ($selectedLangConfig.foldersCreatedMessage -f $sourceFolder) -ForegroundColor White
    Write-Host " - $sourceFolder" -ForegroundColor Green  # Diese Zeile hinzufügen
    Write-Host " - $processedFolder" -ForegroundColor Green
    Write-Host " - $outputFolder" -ForegroundColor Green
    Write-Host ""
    Write-Host "$($selectedLangConfig.filesAddedMessage -f $sourceFolder)" -ForegroundColor White
    Write-Host ""
    Write-Host $selectedLangConfig.pressAnyKeyContinueMessage -ForegroundColor Red
    [void][System.Console]::ReadKey() # Warten auf Tastendruck
    cls
    & $MyInvocation.MyCommand.Path # Skript erneut starten
} else {
    # Erfassen aller Dateien im $sourceFolder
    $sourceFiles = Get-ChildItem -Path $sourceFolder -File
    # Filtern der Dateien, um nur diejenigen mit der Endung ".log" beizubehalten
    $sourceFiles = $sourceFiles | Where-Object { $_.Extension -eq ".log" }
    if ($sourceFiles.Count -eq 0) {
        # Ausgabe der Meldung im Konsolenfenster
        cls
        Write-Host "$($selectedLangConfig.filesNotFoundMessage -f $sourceFolder)" -ForegroundColor White
        Write-Host " -> $sourceFolder" -ForegroundColor Cyan
        Write-Host ""
        Write-Host $selectedLangConfig.restartScriptMessage -ForegroundColor White
        Write-Host ""
        Write-Host $selectedLangConfig.pressAnyKeyContinueMessage -ForegroundColor Red
        [void][System.Console]::ReadKey() # Warten auf Tastendruck
        cls
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
        cls
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
