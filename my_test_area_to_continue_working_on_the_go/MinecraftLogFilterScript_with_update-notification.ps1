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
Autor: RaptorXilef
GitHub: https://github.com/raptorxilef/MinecraftLogFilterScript
Lizenz: GNU GENERAL PUBLIC LICENSE - Version 3, 29 June 2007
#>
# ToDo 1. Mit "Visual Studio Code" gefundene Fehler beseitigen ✔
# ToDo 2. Code nach konvention strukturieren und in Formeln aufgliedern
# ToDo 3. Nach update suchen, bevor eine config.yml existiert, wenn existiert erst: ✔
# ToDo     Updatefunktion am Ende des Skripts ausführen, nach der Ausgabe der gefilterten Daten ✔
# Todo 4. Funktion einbauen, in Config die Updates zu deaktivieren/aktivieren. 


# >>>>Funktionen<<<<
function CheckIfUpdateIsAvailable {
    param (
        [string]$currentVersion,
        [string]$repoOwner,
        [string]$repoName,
        [bool] $firstStart
    )

    # Definition der Funktion Get-LatestVersionFromGitHub zum abrufen der Versionsnummer aus tag_name von GitHub # Definition of the Get-LatestVersionFromGitHub function to retrieve the version number from tag_name from GitHub
    function Get-LatestVersionFromGitHub_FirstStart($releaseUrlApi) {
        # Variablen
        # $releaseUrlApi = "https://api.github.com/repos/$repoOwner/$repoName/releases" # <-------- Use this if you also want to check for pre-releases
        $releaseUrlApi = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
        try {
            $response = Invoke-RestMethod -Uri $releaseUrlApi -Method Get
            $latestVersion = $response.tag_name
            return $latestVersion
        }
        catch {
            Write-Host "GitHub API von MinecraftLogFilterScript nicht erreichbar." -ForegroundColor Red
            Write-Host "Es konnte nicht geprüft werden, ob ein Update verfügbar ist." -ForegroundColor Red
            Write-Host "GitHub API of MinecraftLogFilterScript not accessible." -ForegroundColor Red
            Write-Host "It was not possible to check whether an update is available." -ForegroundColor Red
            return $null
        }
    }

    # Definition der Funktion Get-LatestVersionFromGitHub zum abrufen der Versionsnummer aus tag_name von GitHub # Definition of the Get-LatestVersionFromGitHub function to retrieve the version number from tag_name from GitHub
    function Get-LatestVersionFromGitHub($releaseUrlApi) {
        # Variablen
        # $releaseUrlApi = "https://api.github.com/repos/$repoOwner/$repoName/releases" # <-------- Use this if you also want to check for pre-releases
        $releaseUrlApi = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
        try {
            $response = Invoke-RestMethod -Uri $releaseUrlApi -Method Get
            $latestVersion = $response.tag_name
            return $latestVersion
        }
        catch {
            Write-Host $selectedLangConfig.lang_lastVersionFromGitHub_errorMessage1 -ForegroundColor Red
            Write-Host $selectedLangConfig.lang_lastVersionFromGitHub_errorMessage2 -ForegroundColor Red
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
                $answerChoose = $false
                do {    
                    Clear-Host            
                    Write-Host "Info" -ForegroundColor White
                    Write-Host ""
                    Write-Host "[DE] Es ist ein Update verfügbar!" -ForegroundColor Yellow
                    Write-Host "[DE] Installierte Version: $currentVersion ($currentVersionSurfix), Neueste Version: $lastVersion ($lastVersionSurfix)"
                    Write-Host "[DE] Möchten Sie die Downloadseite zur letzten Version in Ihrem Browser öffnen? (J/N)"
                    Write-Host ""
                    Write-Host "[EN] An update is available!" -ForegroundColor Yellow
                    Write-Host "[EN] Installed version: $currentVersion ($currentVersionSurfix), Latest version: $lastVersion ($lastVersionSurfix)"
                    $answer = Read-Host "Would you like to open the download page for the latest version in your browser? (Y/N)"

                    if ($answer -eq "J" -or $answer -eq "j" -or $answer -eq "Y" -or $answer -eq "y") {
                        $answerChoose = $true
                        Start-Process $releaseUrl
                    } elseif ($answer -eq "N" -or $answer -eq "n") {
                        $answerChoose = $true
                        Write-Host ""
                        Write-Host "Update" -ForegroundColor White
                        Write-Host ""
                        Write-Host "[DE] Öffnen Sie die Seite $releaseUrl, um das neueste Update anzuzeigen."
                        Write-Host "[DE] Sie können auch die Suche nach Updates in der $configFile deaktivieren."
                        Write-Host "[DE] Drücken Sie eine beliebige Taste, um fortzufahren ..."
                        Write-Host ""
                        Write-Host "[EN] Open the $releaseUrl page to display the latest update."
                        Write-Host "[EN] You can also deactivate the search for updates in the $configFile."
                        Read-Host "[EN] Press any button to continue ..."
                    } else {
                        Write-Host ""
                        Write-Host "Ungültige Auswahl." -ForegroundColor Red
                        Write-Host "Invalid selection." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                } while ($false -eq $answerChoose)
            
            }
        }
    }

    # Definition der Funktion CheckForUpdate zum Ausgeben, ob ein Update verfügbar ist, oder nicht. # Definition of the CheckForUpdate function to output whether an update is available or not.
    function Test-UpdateAvailableWithConfig($currentVersion, $lastVersion, $repoOwner, $repoName) {
        $releaseUrl = "https://github.com/$repoOwner/$repoName/releases/latest"
        if ($lastVersion) {
            if (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -eq $lastVersionSurfixValueAsNumber) -or (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -gt $lastVersionSurfixValueAsNumber) -or ($currentVersion -gt $lastVersion))) {
                Write-Host $selectedLangConfig.lang_updateAvailable_info -ForegroundColor White
                Write-Host ""
                Write-Host $selectedLangConfig.lang_updateAvailable_upToDate1 $currentVersion ($currentVersionSurfix) $selectedLangConfig.lang_updateAvailable_upToDate2 -ForegroundColor Green
            } elseif (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -lt $lastVersionSurfixValueAsNumber) -or ($currentVersion -lt $lastVersion)) {
                $answerChoose = $false
                do {
                    Clear-Host
                    Write-Host $selectedLangConfig.lang_updateAvailable_info -ForegroundColor White
                    Write-Host ""
                    Write-Host $selectedLangConfig.lang_updateAvailable_updateAvailable -ForegroundColor Yellow
                    Write-Host $selectedLangConfig.lang_updateAvailable_installedVersion $currentVersion ($currentVersionSurfix), $selectedLangConfig.lang_updateAvailable_latestVersion $lastVersion ($lastVersionSurfix)
                    $answer = Read-Host $selectedLangConfig.lang_updateAvailable_askOpenDownloadPage

                    if ($answer -eq "J" -or $answer -eq "j" -or $answer -eq "Y" -or $answer -eq "y") {
                        $answerChoose = $true
                        Start-Process $releaseUrl
                    } elseif ($answer -eq "N" -or $answer -eq "n") {
                        $answerChoose = $true
                        Write-Host ""
                        Write-Host $selectedLangConfig.lang_updateAvailable_showDownloadPage1 -ForegroundColor White
                        Write-Host ""
                        Write-Host $selectedLangConfig.lang_updateAvailable_showDownloadPage2 $releaseUrl $selectedLangConfig.lang_updateAvailable_showDownloadPage3
                        Write-Host $selectedLangConfig.lang_updateAvailable_showDownloadPage4 $configFile $selectedLangConfig.lang_updateAvailable_showDownloadPage5
                        Read-Host $selectedLangConfig.lang_updateAvailable_showDownloadPage6
                    } else {
                        Write-Host ""
                        Write-Host $selectedLangConfig.lang_invalideSelection -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                } while ($false -eq $answerChoose)
            
            }
        }
    }




    # Aufruf der Funktion Get-LatestVersionFromGitHub # Calling the Get-LatestVersionFromGitHub function
    if ($firstStart -eq $true) {
        # Aufruf der Funktion CheckForUpdate
        # Write-Host $firstStart $true
        $lastVersion = Get-LatestVersionFromGitHub_FirstStart $releaseUrlApi
    } else {
        # Aufruf der Funktion CheckForUpdate
        # Write-Host $firstStart $false
        $lastVersion = Get-LatestVersionFromGitHub $releaseUrlApi
    }

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
    # Write-Host "Aktuelle Version: $currentVersion ($currentVersionSurfix)"
    # Write-Host "Neueste Version: $lastVersion ($lastVersionSurfix)"

    # Version-Surfix in nummerischen Wert umwandeln # Convert version surfix to numerical value
    $currentVersionSurfixValueAsNumber = Test-IsVersionsSurfixChange -versionSurfix $currentVersionSurfix
    $lastVersionSurfixValueAsNumber = Test-IsVersionsSurfixChange -versionSurfix $lastVersionSurfix

    #if (-not (Test-Path $configFile -PathType Leaf)) {
    if ($firstStart -eq $true) {
        # Aufruf der Funktion CheckForUpdate
        Test-UpdateAvailableWithoutConfig $currentVersion $lastVersion $repoOwner $repoName
    } else {
        # Aufruf der Funktion CheckForUpdate
        Test-UpdateAvailableWithConfig $currentVersion $lastVersion $repoOwner $repoName
    }
}

function Write-YamlDEToFile {
    param (
        [string]$FilePath
    )

    $defaultLangDEConfig = @"
# Die Versionsnummer niemals bearbeiten!
langDEConfigVersion: "$langDEFileVersion"

# Die deutschen Texte
lang_lastVersionFromGitHub_errorMessage1: "GitHub API von MinecraftLogFilterScript nicht erreichbar."
lang_lastVersionFromGitHub_errorMessage2: "Es konnte nicht geprüft werden, ob ein Update verfügbar ist."
lang_updateAvailable_info: "Info"
lang_updateAvailable_upToDate1: "Die installierte Version:"
lang_updateAvailable_upToDate2: "ist auf dem neuesten Stand."
lang_updateAvailable_updateAvailable: "Es ist ein Update verfügbar!"
lang_updateAvailable_installedVersion: "Installierte Version:"
lang_updateAvailable_latestVersion: "Neueste Version:"
lang_updateAvailable_askOpenDownloadPage: "Möchten Sie die Downloadseite zur letzten Version in Ihrem Browser öffnen? (J/N)"
lang_updateAvailable_showDownloadPage1: "Update"
lang_updateAvailable_showDownloadPage2: "Öffnen Sie die Seite"
lang_updateAvailable_showDownloadPage3: ", um das neueste Update anzuzeigen."
lang_updateAvailable_showDownloadPage4: "Sie können auch die Suche nach Updates in der"
lang_updateAvailable_showDownloadPage5: "deaktivieren."
lang_updateAvailable_showDownloadPage6: "Drücken Sie eine beliebige Taste, um fortzufahren ..."
lang_invalideSelection: "Ungültige Auswahl."
lang_configCreatedMessage: "Die Konfigurationsdatei '{0}' wurde erstellt."
lang_configEditMessage: "Bitte bearbeiten Sie diese Datei, um die Sprache, Filterbegriffe und Ordnerpfade anzupassen."
lang_pressAnyKeyContinueMessage: "Drücken Sie eine beliebige Taste, um fortzufahren."
lang_foldersCreatedMessage: "Es wurden Ordner erstellt:"
lang_filesAddedMessage: "Bitte füge im Ordner {0} die zu filternde/n Log-Dateie/n ein. Fahre anschließend fort."
lang_restartScriptMessage: "Fahre anschließend fort."
lang_filesNotFoundMessage: "Bitte füge im Ordner {0} die zu filternde/n Log-Dateie/n ein."
lang_processingLogsMessage: "Die Log-Dateien werden verarbeitet. Bitte habe einen Moment Geduld."
lang_pleaseWaitMessage: "Bitte warten..."
lang_processingFinishAMessage: "Die Verarbeitung von"
lang_processingFinishBMessage: "war erfolgreich."
lang_processingFinishFoundMessage: "Gefunden"
lang_processingFinishFolderInfoMessage: "Sie finden die Filterergebnisse unter"
lang_scriptFinishedMessage: "Sie können das Konsolenfenster nun schließen oder mit einer beliebigen Taste neu starten!"
"@
    $defaultLangDEConfig | Out-File -FilePath $FilePath -Encoding utf8
}
function Write-YamlENToFile {
    param (
        [string]$FilePath
    )

    $defaultLangENConfig = @"
# Never edit the version number!
langENConfigVersion: "$langENFileVersion"

# English texts here
lang_lastVersionFromGitHub_errorMessage1: "GitHub API of MinecraftLogFilterScript not accessible."
lang_lastVersionFromGitHub_errorMessage2: "It was not possible to check whether an update is available."
lang_updateAvailable_info: "Info"
lang_updateAvailable_upToDate1: "The installed version:"
lang_updateAvailable_upToDate2: "is up to date."
lang_updateAvailable_updateAvailable: "An update is available!"
lang_updateAvailable_installedVersion: "Installed version:"
lang_updateAvailable_latestVersion: "Latest version:"
lang_updateAvailable_askOpenDownloadPage: "Would you like to open the download page for the latest version in your browser? (Y/N)"
lang_updateAvailable_showDownloadPage1: "Update"
lang_updateAvailable_showDownloadPage2: "Open the"
lang_updateAvailable_showDownloadPage3: "page to display the latest update."
lang_updateAvailable_showDownloadPage4: "You can also deactivate the search for updates in the"
lang_updateAvailable_showDownloadPage5: "."
lang_updateAvailable_showDownloadPage6: "Press any button to continue ..."
lang_invalideSelection: "Invalid selection."
lang_configCreatedMessage: "The configuration file '{0}' has been created."
lang_configEditMessage: "Please edit this file to customize the language, filter terms and folder paths."
lang_pressAnyKeyContinueMessage: "Press any button to continue."
lang_foldersCreatedMessage: "Folders have been created:"
lang_filesAddedMessage: "Please add the log file(s) to be filtered in the folder {0}. Then continue."
lang_restartScriptMessage: "Then continue."
lang_filesNotFoundMessage: "Please add the log file/s to be filtered in the folder {0}."
lang_processingLogsMessage: "The log files are being processed. Please be patient for a moment."
lang_pleaseWaitMessage: "Please wait..."
processingFinishMessage: "Processing successful!"
processingResultMessage: "Result:"
lang_processingFinishAMessage: "The processing of"
lang_processingFinishBMessage: "was successful."
lang_processingFinishFoundMessage: "Found"
lang_processingFinishFolderInfoMessage: "You can find the filter results under"
lang_scriptFinishedMessage: "You can now close the console window or restart it by pressing any key!"
"@
    $defaultLangENConfig | Out-File -FilePath $FilePath -Encoding utf8
}

function Write-YamlConfigToFile {
    param (
        [string]$FilePath
    )

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
# default: "processedLog"
# Ordner für die bereits verarbeiteten Dateien.
# Standart: "verarbeitetLog"
processedFolder: "verarbeitetLog"

# Folder for the gz-archiv-files that have already been processed.
# default: "processedGz"
# Ordner für die bereits verarbeiteten gz-Archiv-Dateien.
# Standart: "verarbeitetGz"
processedFolderGz: "verarbeitetGz"

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
    $defaultConfig | Out-File -FilePath $FilePath -Encoding utf8

    # Laden der ausgewählten Sprachkonfiguration basierend auf der Sprache in der config.yml
    $config = Get-Content $configFile | ConvertFrom-Yaml
    $lang = $config.lang
    $selectedLangConfig = if ($lang -eq "de") { $langDEConfig } elseif  ($lang -eq "en") { $langENConfig } else {$langENConfig}

        # Ausgabe der Meldung im Konsolenfenster
        Clear-Host
        Write-Host "$($selectedLangConfig.lang_configCreatedMessage -f $configFile)" -ForegroundColor Yellow
        Write-Host $selectedLangConfig.lang_configEditMessage -ForegroundColor Yellow
        Write-Host ""
        Write-Host $selectedLangConfig.lang_pressAnyKeyContinueMessage -ForegroundColor Red
        [void][System.Console]::ReadKey() # Warten auf Tastendruck
        Clear-Host
}

function UpdateLangFilesIfOutDate {
    param (
        [string]$configFolder,
        [string]$langDEFile,
        [string]$langENFile,
        [string]$langDEFileVersion,
        [string]$langENFileVersion
    )

    if ($langDEConfig.langDEConfigVersion -ne $langDEFileVersion) {
        # Umbenennen der vorhandenen deutschen Sprachdatei mit einem zählenden Suffix
        $count = 0
        while (Test-Path $langDEFile) {
            $count++
            $newName = "lang-de-old$count.yml"
            # Write-Host "$configFolder$newName" -ForegroundColor GREEN # ? Zur Fehleranalyse
            if (-not (Test-Path $configFolder$newName)) {
                Rename-Item -Path $langDEFile -NewName $newName
                break
            }
            Start-Sleep -Milliseconds 100  # Kurze Wartezeit
        }
        
        Start-Sleep -Seconds 1
        # Erstellen einer neuen deutschen Sprachdatei mit den Standardinhalten
        Write-YamlDEToFile -FilePath $langDEFile
        Write-Host ""
        Write-Host "[DE] Die Datei: $langDEFile entsprach nicht der benötigten Version und wurde daher neu erstellt." -ForegroundColor Red
        Write-Host "Von der ursprünglichen Datei wurde ein Backup angelegt." -ForegroundColor Red
        Write-Host "[EN] The file: $langDEFile did not correspond to the required version and was therefore recreated." -ForegroundColor Red
        Write-Host "A backup of the original file was created." -ForegroundColor Red
    }

    if ($langENConfig.langENConfigVersion -ne $langENFileVersion) {
        # Umbenennen der vorhandenen englischen Sprachdatei mit einem zählenden Suffix
        $count = 0
        while (Test-Path $langENFile) {
            $count++
            $newName = "lang-en-old$count.yml"
            # Write-Host "$configFolder$newName" -ForegroundColor GREEN # ? Zur Fehleranalyse
            if (-not (Test-Path $configFolder$newName)) {
                Rename-Item -Path $langENFile -NewName $newName
                break
            }
            Start-Sleep -Milliseconds 100  # Kurze Wartezeit
        }
        Start-Sleep -Seconds 1
        # Erstellen einer neuen englischen Sprachdatei mit den Standardinhalten
        Write-YamlENToFile -FilePath $langENFile
        Write-Host ""
        Write-Host "[DE] Die Datei: $langENFile entsprach nicht der benötigten Version und wurde daher neu erstellt." -ForegroundColor Red
        Write-Host "Von der ursprünglichen Datei wurde ein Backup angelegt." -ForegroundColor Red
        Write-Host "[EN] The file: $langENFile did not correspond to the required version and was therefore recreated." -ForegroundColor Red
        Write-Host "A backup of the original file was created." -ForegroundColor Red
    }
}

function set-Language {
    param (
        [string[]]$availableLanguages
    )

    $selectedLang = $null
    do {
        Clear-Host
        Write-Host "[DE] Bitte wählen Sie Ihre Sprache:" -ForegroundColor Yellow
        Write-Host "[EN] Please select your language:" -ForegroundColor Yellow
        Write-Host ""
        for ($i=0; $i -lt $availableLanguages.Count; $i++) {
            Write-Host "$i. $($availableLanguages[$i])" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "[DE] Geben Sie die entsprechende Nummer ein und bestätigen Sie diese mit Enter."
        Write-Host "[EN] Type in the corresponding number and confirm with Enter."
        $userInput = Read-Host
        if ($userInput -ge 0 -and $userInput -lt $availableLanguages.Count) {
            $selectedLang = $availableLanguages[$userInput]
        } else {
            Write-Host "[DE] Ungültige Auswahl." -ForegroundColor Red
            Write-Host "[EN] Invalid selection." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    } while ($null -eq $selectedLang)
    return $selectedLang
}

function create-WorkFolders {
    param (
        [string]$sourceFolder,
        [string]$outputFolder,
        [string]$processedFolder
    )

    # Erstellen der Ordner, falls sie nicht existieren
    New-Item -ItemType Directory -Path $sourceFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $processedFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $processedFolderGz -Force | Out-Null

    # Ausgabe der Meldung im Konsolenfenster
    Clear-Host
    Write-Host ($selectedLangConfig.lang_foldersCreatedMessage -f $sourceFolder) -ForegroundColor White
    Write-Host " - $sourceFolder" -ForegroundColor Green  # Diese Zeile hinzufügen
    Write-Host " - $processedFolder" -ForegroundColor Green
    Write-Host " - $processedFolderGz" -ForegroundColor Green
    Write-Host " - $outputFolder" -ForegroundColor Green
    Write-Host ""
    Write-Host "$($selectedLangConfig.lang_filesAddedMessage -f $sourceFolder)" -ForegroundColor White
    Write-Host ""
    Write-Host $selectedLangConfig.lang_pressAnyKeyContinueMessage -ForegroundColor Red
    [void][System.Console]::ReadKey() # Warten auf Tastendruck
    Clear-Host
}

function missing-logFiles {
    param (
        [string]$sourceFolder
    )

    # Ausgabe der Meldung im Konsolenfenster
    Clear-Host
    Write-Host "$($selectedLangConfig.lang_filesNotFoundMessage -f $sourceFolder)" -ForegroundColor White
    Write-Host " -> $sourceFolder" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $selectedLangConfig.lang_restartScriptMessage -ForegroundColor White
    Write-Host ""
    Write-Host $selectedLangConfig.lang_pressAnyKeyContinueMessage -ForegroundColor Red
    [void][System.Console]::ReadKey() # Warten auf Tastendruck
    Clear-Host
}

function filter-logFilesGz {
    param (
        [string]$outputFolder,
        [string]$processedFolderGz
    )

    # Prüfen, ob $outputFolder existiert
    if (-not (Test-Path $outputFolder -PathType Container)) {
        # Erstellen des Ordners, falls er nicht existiert
        New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    }

    # Prüfen, ob $processedFolderGz existiert
    if (-not (Test-Path $processedFolderGz -PathType Container)) {
        # Erstellen des Ordners, falls er nicht existiert
        New-Item -ItemType Directory -Path $processedFolderGz -Force | Out-Null
    }

    # Meldung vor dem Verarbeiten der Log-Dateien anzeigen
    Clear-Host
    Write-Host $selectedLangConfig.lang_processingLogsMessage -ForegroundColor Yellow
    Write-Host $selectedLangConfig.lang_pleaseWaitMessage -ForegroundColor Yellow
    Write-Host ""





    # Liste alle .gz-Dateien im Quellordner auf
    $gzFiles = Get-ChildItem -Path $sourceFolder -Filter "*.gz"

    # Überprüfe, ob mindestens eine .gz-Datei vorhanden ist
    if ($gzFiles.Count -gt 0) {
        Write-Output "Es sind $($gzFiles.Count) .gz-Dateien im Ordner vorhanden."

            # Liste alle .gz-Dateien im Quellordner auf
            $gzFiles = Get-ChildItem -Path $sourceFolder -Filter "*.gz"

            # Extrahiere und verschiebe jede .gz-Datei
            foreach ($gzFile in $gzFiles) {
                # Bestimme den Dateinamen ohne Erweiterung
                $outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($gzFile.Name)

                # Definiere den vollständigen Pfad zur Ausgabedatei
                $outputFilePath = Join-Path -Path $sourceFolder -ChildPath $outputFileName

                # Erstelle ein FileStream-Objekt für die .gz-Datei
                $fileStream = [System.IO.File]::OpenRead($gzFile.FullName) # ToDo - Optional: Wenn schon vorhanden, Zahl an Namen anhängen

                # Erstelle ein GZipStream-Objekt für die Dekomprimierung
                $gzipStream = [System.IO.Compression.GZipStream]::new($fileStream, [System.IO.Compression.CompressionMode]::Decompress)



                # Definiere den vollständigen Pfad zur Ausgabedatei
                $outputFileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($outputFileName)
                $extension = [System.IO.Path]::GetExtension($outputFileName)
                $counter = 1
                while (Test-Path (Join-Path -Path $sourceFolder -ChildPath "$outputFileNameWithoutExtension`_$counter$extension")) {
                    $counter++
                }
                $outputFilePath = Join-Path -Path $sourceFolder -ChildPath "$outputFileNameWithoutExtension`_$counter$extension"
                $outputFileStream = [System.IO.File]::Create($outputFilePath)

                

                # Kopiere den Inhalt der GZip-Datei in die Ausgabedatei
                $gzipStream.CopyTo($outputFileStream)

                # Schließe die Streams
                $fileStream.Close()
                $outputFileStream.Close()
                $gzipStream.Close()

                # Move-Item -Path $gzFile.FullName -Destination (Join-Path -Path $processedFolderGz -ChildPath $gzFile.Name) # ToDo Wenn schon vorhanden Zahl an Namen anhängen
                # Verschiebe die .gz-Datei in den processedFolderGz
                $destinationFileName = $gzFile.Name
                $counter = 1
                while (Test-Path (Join-Path -Path $processedFolderGz -ChildPath $destinationFileName)) {
                    $outputFileName = $outputFileName -replace '\.gz$', ''
                    $destinationFileName = "{0}_{1}.gz" -f $outputFileName, $counter
                    $counter++
                }
                Move-Item -Path $gzFile.FullName -Destination (Join-Path -Path $processedFolderGz -ChildPath $destinationFileName)
                Start-Sleep -Seconds 2
            }

    } else {
        Write-Output "Es sind keine .gz-Dateien im Ordner vorhanden."
    }
}

function filter-logFiles {
    param (
        [string]$outputFolder,
        [string]$processedFolder
    )

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
    Write-Host $selectedLangConfig.lang_processingLogsMessage -ForegroundColor Yellow
    Write-Host $selectedLangConfig.lang_pleaseWaitMessage -ForegroundColor Yellow
    Write-Host ""

    
    # Filtervorgang für jede Logdatei durchführen
    foreach ($sourceFile in $sourceFiles) {
        if ($sourceFile.Extension -eq ".log") {
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
            Write-Host "$($selectedLangConfig.lang_processingFinishAMessage) '$($sourceFile.Name)' $($selectedLangConfig.lang_processingFinishBMessage)" -ForegroundColor Green
            Write-Host "    $($selectedLangConfig.lang_processingFinishFolderInfoMessage):" -ForegroundColor White
            Write-Host "     - $($processedFolder)\$($sourceFileName)" -ForegroundColor Cyan

            Write-Host "    $($selectedLangConfig.lang_processingFinishFoundMessage):" -ForegroundColor White
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





# >>>>Variablen<<<<
    # Pfad zum Skriptordner
    $configFolder = "MinecraftLogFilter\"
    # Pfad zur Konfigurationsdatei
    $configFile = $configFolder + "config.yml"

    # Liste der verfügbaren Sprachen
    $availableLanguages = @("de", "en")
    # Pfad zur Sprachkonfigurationsdatei für Deutsch
    $langDEFile = $configFolder + "lang-de.yml"
    # Pfad zur Sprachkonfigurationsdatei für Englisch
    $langENFile = $configFolder + "lang-en.yml"

    # Aktuelle Versionsnummer und Repository-Daten von GitHub zum Abrufen der Versionsnummer aus der GitHub-API # Current version number and repository data from GitHub to retrieve the version number from the GitHub API
    $currentVersion = "0.0.2-alpha" # <----------- VERSION
    $repoOwner = "RaptorXilef"
    $repoName = "MinecraftLogFilterScript"

    # Versionsvariablen für die Konfigurationsdatei und die Sprachkonfigurationsdateien
    $configFileVersion = "2"
    $langDEFileVersion = "2"
    $langENFileVersion = "2"




# >>>>Abrufen der Funktionen<<<<
# Überprüfen, ob das Modul powershell-yaml installiert ist, wenn nicht, installiere es
if (-not (Get-Module -Name powershell-yaml -ListAvailable)) {
    Write-Host "[DE] Das Modul 'powershell-yaml' wird benötigt um die config.yml zu lesen, welche die Filtereinstellungen enthält. Es wird jetzt installiert..." -ForegroundColor Yellow
    Write-Host "[EN] The module 'powershell-yaml' is needed to read the config.yml, which contains the filter settings. It will now be installed..." -ForegroundColor Yellow
    Install-Module -Name powershell-yaml -Scope CurrentUser -Force
}
# Importieren des Moduls powershell-yaml
Import-Module -Name powershell-yaml


if (-not (Get-Module -Name Microsoft.PowerShell.Archive -ListAvailable)) {
    Write-Host "[DE] Das Modul 'Microsoft.PowerShell.Archive' wird benötigt um die LOG.gz Dateien zu lesen. Es wird jetzt installiert..." -ForegroundColor Yellow
    Write-Host "[EN] The module 'Microsoft.PowerShell.Archive' is required to read the LOG.gz files. It will now be installed..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.PowerShell.Archive -Scope CurrentUser -Force
}
# Importieren des System.IO.Compression-Moduls für die Arbeit mit komprimierten Dateien
Import-Module -Name Microsoft.PowerShell.Archive

# Prüfen, ob $configFolder existiert
if (-not (Test-Path $configFolder -PathType Container)) {
    $firstStartInput = $true
    Write-Host "[DE] Prüfe auf Updates. Bitte warten!" -ForegroundColor Green
    Write-Host "[EN] Check for updates. Please wait!" -ForegroundColor Green
    Write-Host ""
    Write-Host ""
    #Prüfe auf Updates bevor das Skript das erste mal ausgeführt wird
    CheckIfUpdateIsAvailable -firstStart $firstStartInput -currentVersion $currentVersion -repoOwner $repoOwner -repoName $repoName
    Start-Sleep -Seconds 3
    # Erstellen des Ordners, falls er nicht existiert
    New-Item -ItemType Directory -Path $configFolder -Force | Out-Null
} else {
    $firstStartInput = $false
}

# Prüfen, ob die Sprachkonfigurationsdatei für Deutsch existiert, andernfalls erstellen
if (-not (Test-Path $langDEFile -PathType Leaf)) {
    Write-YamlDEToFile -FilePath $langDEFile
}

# Prüfen, ob die Sprachkonfigurationsdatei für Englisch existiert, andernfalls erstellen
if (-not (Test-Path $langENFile -PathType Leaf)) {
    Write-YamlENToFile -FilePath $langENFile
}

# Laden der Sprachkonfiguration für Deutsch
$langDEConfig = Get-Content $langDEFile | ConvertFrom-Yaml
# Laden der Sprachkonfiguration für Englisch
$langENConfig = Get-Content $langENFile | ConvertFrom-Yaml

if ($langDEConfig.langDEConfigVersion -ne $langDEFileVersion -or $langENConfig.langENConfigVersion -ne $langENFileVersion) {
    # Aufruf der Funktion für die Aktualisierung der Sprachdateien bei nicht Übereinstimmung der Versionsnummer
    UpdateLangFilesIfOutDate -configFolder $configFolder -langDEFile $langDEFile -langENFile $langENFile -langDEFileVersion $langDEFileVersion -langENFileVersion $langENFileVersion
    $langDEConfig = Get-Content $langDEFile | ConvertFrom-Yaml
    $langENConfig = Get-Content $langENFile | ConvertFrom-Yaml
}

# Create config-file
if (-not (Test-Path $configFile -PathType Leaf)) {
    # set Language # Wähle Sprache
    $selectedLang = set-Language -availableLanguages $availableLanguages
    Write-YamlConfigToFile -FilePath $configFile

    & $MyInvocation.MyCommand.Path # Skript erneut starten
    EXIT
}

# Laden der ausgewählten Sprachkonfiguration basierend auf der Sprache in der config.yml
$config = Get-Content $configFile | ConvertFrom-Yaml
$lang = $config.lang
$selectedLangConfig = if ($lang -eq "de") { $langDEConfig } elseif  ($lang -eq "en") { $langENConfig } else {$langENConfig}

# Festlegen der Variablen für Pfade aus der Konfiguration
$sourceFolder = $configFolder + $config.sourceFolder
$outputFolder = $configFolder + $config.outputFolder
$processedFolder = $configFolder + $config.processedFolder
$processedFolderGz = $configFolder + $config.processedFolderGz

# Prüfen, ob $sourceFolder existiert
if (-not (Test-Path $sourceFolder -PathType Container)) {
    create-WorkFolders -sourceFolder $sourceFolder -outputFolder $outputFolder -processedFolder $processedFolder
    & $MyInvocation.MyCommand.Path # Skript erneut starten
    EXIT
} else {
    # Erfassen aller Dateien im $sourceFolder
    $sourceFiles = Get-ChildItem -Path $sourceFolder -File
    # Filtern der Dateien, um nur diejenigen mit der Endung ".log" und ".gz" beizubehalten
    $sourceFiles = $sourceFiles | Where-Object { $_.Extension -eq ".log" -or $_.Extension -eq ".gz" }
    if ($sourceFiles.Count -eq 0) {
        missing-logFiles -sourceFolder $sourceFolder
        & $MyInvocation.MyCommand.Path # Skript erneut starten
        EXIT
    } else {
        # Erfassen aller GZ-Dateien im $sourceFolder
        $sourceFiles = Get-ChildItem -Path $sourceFolder -File
        # Filtern der Dateien, um nur diejenigen mit der Endung ".log" und ".gz" beizubehalten
        $sourceFiles = $sourceFiles | Where-Object { $_.Extension -eq ".gz" }
        
        # Filtert die Log-Dateien und gibt das Ergebnis aus
        filter-logFilesGz -outputFolder $outputFolder -processedFolderGz $processedFolderGz

        # Erfassen aller Log-Dateien im $sourceFolder
        $sourceFiles = Get-ChildItem -Path $sourceFolder -File
        # Filtern der Dateien, um nur diejenigen mit der Endung ".log" und ".gz" beizubehalten
        $sourceFiles = $sourceFiles | Where-Object { $_.Extension -eq ".log" }

        filter-logFiles -outputFolder $outputFolder -processedFolder $processedFolder
        # Ausgabe der Abschlussmeldung
        Write-Host "" -ForegroundColor White
        Write-Host $selectedLangConfig.lang_scriptFinishedMessage -ForegroundColor Red
        Write-Host ""
        Write-Host ""
        Write-Host ""
        CheckIfUpdateIsAvailable -firstStart $firstStartInput -currentVersion $currentVersion -repoOwner $repoOwner -repoName $repoName
        [void][System.Console]::ReadKey() # Warten auf Tastendruck
        # Suche nach Update
        & $MyInvocation.MyCommand.Path # Skript erneut starten
        EXIT
    }
}
EXIT





















