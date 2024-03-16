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

# >>>>Funktionen<<<< # >>>>Functions<<<<
function Test-ForUpdateAvailability {
    param (
        [string]$currentVersion,
        [string]$repoOwner,
        [string]$repoName,
        [bool] $firstStart
    )

    # Definition der Funktion Get-LatestGitHubVersion zum abrufen der Versionsnummer aus tag_name von GitHub # Definition of the Get-LatestGitHubVersion function to retrieve the version number from tag_name from GitHub
    function Get-LatestGitHubVersionOnFirstStart($releaseUrlApi) {
        # Variablen # Variables
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

    # Definition der Funktion Get-LatestGitHubVersion zum abrufen der Versionsnummer aus tag_name von GitHub # Definition of the Get-LatestGitHubVersion function to retrieve the version number from tag_name from GitHub
    function Get-LatestGitHubVersion($releaseUrlApi) {
        # Variablen # Variables
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
    function Split-VersionAndSuffix {
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
    function Remove-VPrefix {
        param (
            [string]$version
        )

        if ($version) {
            # Write-Host "String mit 'v': $version" # ? Zur Fehleranalyse
            # Überprüfen, ob der String mit "v" beginnt # Check whether the string begins with "v"
            if ($version.StartsWith("v")) {
                # Entfernen des "v" vom Anfang des Strings # Remove the "v" from the beginning of the string
                $version = $version.Substring(1)
                # Write-Host "String ohne 'v': $version" # ? Zur Fehleranalyse
            }

            # Rückgabe der Ergebnisse # Return of the results
            return $version
        }
    }

    # Funktion zur Konvertierung ins System.Version Format # Function for converting to System.version format
    function Convert-ToSystemVersion {
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
    function Convert-PreReleaseToInt {
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
    function Test-UpdateAvailabilityWithoutExistConfigFile($currentVersion, $lastVersion, $repoOwner, $repoName) {
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
    function Test-UpdateAvailabilityWithExistConfigFile($currentVersion, $lastVersion, $repoOwner, $repoName) {
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




    # Aufruf der Funktion Get-LatestGitHubVersion # Calling the Get-LatestGitHubVersion function
    if ($firstStart -eq $true) {
        # Aufruf der Funktion Get-LatestGitHubVersionOnFirstStart # Calling the Get-LatestGitHubVersionOnFirstStart function
        # Write-Host $firstStart $true # ? Zur Fehleranalyse
        $lastVersion = Get-LatestGitHubVersionOnFirstStart $releaseUrlApi
    } else {
        # Aufruf der Funktion Get-LatestGitHubVersion # Calling the Get-LatestGitHubVersion function
        # Write-Host $firstStart $false # ? Zur Fehleranalyse
        $lastVersion = Get-LatestGitHubVersion $releaseUrlApi
    }

    # Trennung von Versionsnummer und Suffix für aktuelle und letzte Version # Separation of version number and suffix for current and last version
    $currentVersion, $currentVersionSurfix = Split-VersionAndSuffix -version $currentVersion
    $lastVersion, $lastVersionSurfix = Split-VersionAndSuffix -version $lastVersion

    # Setzt die Versionsbezeichnung auf stabile wenn diese nicht gesetzt wurde # Sets the version designation to stabile if this has not been set
    if ($currentVersionSurfix) {} else {$currentVersionSurfix = "stabile"}
    if ($lastVersionSurfix) {} else {$lastVersionSurfix = "stabile"}

    # Entfernen des "v" vom Anfang des Strings, wenn es existiert # Remove the "v" from the beginning of the string if it exists
    $currentVersion = Remove-VPrefix -version $currentVersion
    $lastVersion = Remove-VPrefix -version $lastVersion

    # Konvertierung von $currentVersion von String in Version # Conversion of $currentVersion from string to version
    $currentVersion = Convert-ToSystemVersion -version $currentVersion
    $lastVersion = Convert-ToSystemVersion -version $lastVersion

    # Test-Ausgabe der aufgetrennten Versionen # Test-output of the split versions
    # Write-Host "Aktuelle Version: $currentVersion ($currentVersionSurfix)" # ? Zur Fehleranalyse
    # Write-Host "Neueste Version: $lastVersion ($lastVersionSurfix)" # ? Zur Fehleranalyse

    # Version-Surfix in nummerischen Wert umwandeln # Convert version surfix to numerical value
    $currentVersionSurfixValueAsNumber = Convert-PreReleaseToInt -versionSurfix $currentVersionSurfix
    $lastVersionSurfixValueAsNumber = Convert-PreReleaseToInt -versionSurfix $lastVersionSurfix

    if ($firstStart -eq $true) {
        # Aufruf der Funktion Test-UpdateAvailabilityWithoutExistConfigFile # Calling the Test-UpdateAvailabilityWithoutExistConfigFile function
        Test-UpdateAvailabilityWithoutExistConfigFile $currentVersion $lastVersion $repoOwner $repoName
    } else {
        # Aufruf der Funktion Test-UpdateAvailabilityWithExistConfigFile # Calling the Test-UpdateAvailabilityWithExistConfigFile function
        Test-UpdateAvailabilityWithExistConfigFile $currentVersion $lastVersion $repoOwner $repoName
    }
}

# Erstellt die lang-de.yml mit Inhalt # Creates the lang-de.yml with content
function New-YamlLangDEFile {
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
lang_newLogFilesFromGzArchive_countGzFilePart1: "Es sind "
lang_newLogFilesFromGzArchive_countGzFilePart2: " .gz-Dateien im Ordner vorhanden."
lang_newLogFilesFromGzArchive_noGzFilePart: "Es sind keine .gz-Dateien im Ordner vorhanden."
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

# Erstellt die lang-en.yml mit Inhalt # Creates the lang-en.yml with content
function New-YamlLangENFile {
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
lang_newLogFilesFromGzArchive_countGzFilePart1: "There are"
lang_newLogFilesFromGzArchive_countGzFilePart2: ".gz files in the folder."
lang_newLogFilesFromGzArchive_noGzFilePart: "There are no .gz files in the folder."
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

# Erstellt die config.yml mit Inhalt # Creates the config.yml with content
function New-YamlConfigFile {
    param (
        [string]$FilePath
    )

    # Konfigurationsdatei mit ausgewählter Sprache erstellen # Create configuration file with selected language
    $defaultConfig = @"
# Never edit the version number!
# Die Versionsnummer niemals bearbeiten!
configVersion: "$configFileVersion"

# Changes the language output in the script.
# default: "en"
# Stellt die Sprachausgabe im Skript um.
# Standard: "de"
lang: "$selectedLang"

# Aktiviert oder deaktiviert die Suche nach Updates.
# default: "true"   -> to activate the update search. "false" to deactivate.
# Activates or deactivates the search for updates.
#Standart: "true"   -> zum aktivieren der Updatesuche. "false" zum deaktivieren.
searchForUpdates: "true"

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

    # Laden der ausgewählten Sprachkonfiguration basierend auf der Sprache aus der config.yml # Load the selected language configuration based on the language in config.yml
    $config = Get-Content $configFile | ConvertFrom-Yaml
    $lang = $config.lang
    $selectedLangConfig = if ($lang -eq "de") { $langDEConfig } elseif  ($lang -eq "en") { $langENConfig } else {$langENConfig}

        # Ausgabe der Meldung im Konsolenfenster # Output of the message in the console window
        Clear-Host
        Write-Host "$($selectedLangConfig.lang_configCreatedMessage -f $configFile)" -ForegroundColor Yellow
        Write-Host $selectedLangConfig.lang_configEditMessage -ForegroundColor Yellow
        Write-Host ""
        Write-Host $selectedLangConfig.lang_pressAnyKeyContinueMessage -ForegroundColor Red
        [void][System.Console]::ReadKey() # Warten auf Tastendruck # Wait for button to be pressed
        Clear-Host
}

# Aktuallisiert die lang-?.yml # Updates the lang-?.yml
function Update-LanguageFiles {
    param (
        [string]$configFolder,
        [string]$langDEFile,
        [string]$langENFile,
        [string]$langDEFileVersion,
        [string]$langENFileVersion
    )

    if ($langDEConfig.langDEConfigVersion -ne $langDEFileVersion) {
        # Umbenennen der vorhandenen deutschen Sprachdatei mit einem zählenden Suffix # Rename the existing German language file with a counting suffix
        $count = 0
        while (Test-Path $langDEFile) {
            $count++
            $newName = "lang-de-old$count.yml"
            # Write-Host "$configFolder$newName" -ForegroundColor GREEN # ? Zur Fehleranalyse
            if (-not (Test-Path $configFolder$newName)) {
                Rename-Item -Path $langDEFile -NewName $newName
                break
            }
            Start-Sleep -Milliseconds 100  # Kurze Wartezeit # Short waiting time
        }
        
        Start-Sleep -Seconds 1
        # Erstellen einer neuen deutschen Sprachdatei mit den Standardinhalten # Create a new German language file with the standard content
        New-YamlLangDEFile -FilePath $langDEFile
        Write-Host ""
        Write-Host "[DE] Die Datei: $langDEFile entsprach nicht der benötigten Version und wurde daher neu erstellt." -ForegroundColor Red
        Write-Host "Von der ursprünglichen Datei wurde ein Backup angelegt." -ForegroundColor Red
        Write-Host "[EN] The file: $langDEFile did not correspond to the required version and was therefore recreated." -ForegroundColor Red
        Write-Host "A backup of the original file was created." -ForegroundColor Red
    }

    if ($langENConfig.langENConfigVersion -ne $langENFileVersion) {
        # Umbenennen der vorhandenen englischen Sprachdatei mit einem zählenden Suffix # Rename the existing English language file with a counting suffix
        $count = 0
        while (Test-Path $langENFile) {
            $count++
            $newName = "lang-en-old$count.yml"
            # Write-Host "$configFolder$newName" -ForegroundColor GREEN # ? Zur Fehleranalyse
            if (-not (Test-Path $configFolder$newName)) {
                Rename-Item -Path $langENFile -NewName $newName
                break
            }
            Start-Sleep -Milliseconds 100  # Kurze Wartezeit # Short waiting time
        }
        Start-Sleep -Seconds 1
        # Erstellen einer neuen englischen Sprachdatei mit den Standardinhalten # Create a new English language file with the standard content
        New-YamlLangENFile -FilePath $langENFile
        Write-Host ""
        Write-Host "[DE] Die Datei: $langENFile entsprach nicht der benötigten Version und wurde daher neu erstellt." -ForegroundColor Red
        Write-Host "Von der ursprünglichen Datei wurde ein Backup angelegt." -ForegroundColor Red
        Write-Host "[EN] The file: $langENFile did not correspond to the required version and was therefore recreated." -ForegroundColor Red
        Write-Host "A backup of the original file was created." -ForegroundColor Red
    }
}

# Wählt die entsprechende Sprache aus # Selects the appropriate language
function Select-Language {
    param (
        [string[]]$availableLanguages
    )

    $selectedLang = $null
    do {
        # Die Konsole leeren # Clear the console
        Clear-Host
        # Eingabeaufforderungen zur Sprachauswahl anzeigen # Display language selection prompts
        Write-Host "[DE] Bitte wählen Sie Ihre Sprache:" -ForegroundColor Yellow
        Write-Host "[EN] Please select your language:" -ForegroundColor Yellow
        Write-Host ""
        # Verfügbare Sprachen anzeigen # Display available languages
        for ($i=0; $i -lt $availableLanguages.Count; $i++) {
            Write-Host "$i. $($availableLanguages[$i])" -ForegroundColor Cyan
        }
        Write-Host ""
        # Eingabeaufforderung zur Sprachauswahl # Language selection input prompt
        Write-Host "[DE] Geben Sie die entsprechende Nummer ein und bestätigen Sie diese mit Enter."
        Write-Host "[EN] Type in the corresponding number and confirm with Enter."
        $userInput = Read-Host
        # Prüfen Sie, ob die Eingabe im Bereich der verfügbaren Sprachen liegt. # Check if the input is within range of available languages
        if ($userInput -ge 0 -and $userInput -lt $availableLanguages.Count) {
            $selectedLang = $availableLanguages[$userInput]
        } else {
            # Den Benutzer über eine ungültige Auswahl benachrichtigen # Notify the user about invalid selection
            Write-Host "[DE] Ungültige Auswahl." -ForegroundColor Red
            Write-Host "[EN] Invalid selection." -ForegroundColor Red
            
            # Kurz pausieren, bevor Sie fortfahren. # Pause briefly before continuing
            Start-Sleep -Seconds 1
        }
    } while ($null -eq $selectedLang)
    # Rückgabe der ausgewählten Sprache # Return the selected language
    return $selectedLang
}

# Erstellt alle nörigen Ordner zur Bearbeitung der .gz und .log Dateien # Creates all necessary folders for editing the .gz and .log files
function Initialize-FileProcessingFolders {
    param (
        [string]$sourceFolder,
        [string]$outputFolder,
        [string]$processedFolder
    )

    # Erstellen der Ordner, falls sie nicht existieren # Create the folders if they do not exist
    New-Item -ItemType Directory -Path $sourceFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $processedFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $processedFolderGz -Force | Out-Null

    # Ausgabe der Meldung im Konsolenfenster # Output of the message in the console window
    Clear-Host
    Write-Host ($selectedLangConfig.lang_foldersCreatedMessage -f $sourceFolder) -ForegroundColor White
    Write-Host " - $sourceFolder" -ForegroundColor Green
    Write-Host " - $processedFolder" -ForegroundColor Green
    Write-Host " - $processedFolderGz" -ForegroundColor Green
    Write-Host " - $outputFolder" -ForegroundColor Green
    Write-Host ""
    Write-Host "$($selectedLangConfig.lang_filesAddedMessage -f $sourceFolder)" -ForegroundColor White
    Write-Host ""
    Write-Host $selectedLangConfig.lang_pressAnyKeyContinueMessage -ForegroundColor Red
    [void][System.Console]::ReadKey() # Warten auf Tastendruck # Wait for button to be pressed
    Clear-Host
}

# Weist auf das Fehlen von .gz oder .log Dateien im Ordner $sourceFolder hin # Indicates the absence of .gz or .log files in the $sourceFolder folder
function Test-FilePresenceInSourceDirectoryByExtensionLogAndGz {
    param (
        [string]$sourceFolder
    )

    # Ausgabe der Meldung im Konsolenfenster # Output of the message in the console window
    Clear-Host
    Write-Host "$($selectedLangConfig.lang_filesNotFoundMessage -f $sourceFolder)" -ForegroundColor White
    Write-Host " -> $sourceFolder" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $selectedLangConfig.lang_restartScriptMessage -ForegroundColor White
    Write-Host ""
    Write-Host $selectedLangConfig.lang_pressAnyKeyContinueMessage -ForegroundColor Red
    [void][System.Console]::ReadKey() # Warten auf Tastendruck # Wait for button to be pressed
    Clear-Host
}

# Entpackt die Log-Dateien aus den gz-Archiven # Extracts the log files from the gz archives
function New-LogFilesFromGzArchive {
    param (
        [string]$outputFolder,
        [string]$processedFolderGz
    )

    # Prüfen, ob $outputFolder existiert # Check whether $outputFolder exists
    if (-not (Test-Path $outputFolder -PathType Container)) {
        # Erstellen des Ordners, falls er nicht existiert # # Create the folder if it does not exist
        New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    }

    # Prüfen, ob $processedFolderGz existiert # Check whether $processedFolderGz exists
    if (-not (Test-Path $processedFolderGz -PathType Container)) {
        # Erstellen des Ordners, falls er nicht existiert # Create the folder if it does not exist
        New-Item -ItemType Directory -Path $processedFolderGz -Force | Out-Null
    }

    # Meldung vor dem Verarbeiten der Log-Dateien anzeigen # Display message before processing the log files
    Clear-Host
    Write-Host $selectedLangConfig.lang_processingLogsMessage -ForegroundColor Yellow
    Write-Host $selectedLangConfig.lang_pleaseWaitMessage -ForegroundColor Yellow
    Write-Host ""





    # Liste alle .gz-Dateien im Quellordner auf # List all .gz files in the source folder
    $gzFiles = Get-ChildItem -Path $sourceFolder -Filter "*.gz"
    # [INT32]$gzCount = $gzFiles.Count

    # Überprüfe, ob mindestens eine .gz-Datei vorhanden ist # Check whether at least one .gz file exists (($($gzFiles.Count)))
    if ($gzFiles.Count -gt 0) {
        # Write-Output $selectedLangConfig.lang_newLogFilesFromGzArchive_countGzFilePart1 $gzCount $selectedLangConfig.lang_newLogFilesFromGzArchive_countGzFilePart2

            # Liste alle .gz-Dateien im Quellordner auf # List all .gz files in the source folder
            $gzFiles = Get-ChildItem -Path $sourceFolder -Filter "*.gz"

            # Extrahiere und verschiebe jede .gz-Datei # Extract and move each .gz file
            foreach ($gzFile in $gzFiles) {
                # Bestimme den Dateinamen ohne Erweiterung # Determine the file name without extension
                $outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($gzFile.Name)

                # Definiere den vollständigen Pfad zur Ausgabedatei # Define the complete path to the output file
                $outputFilePath = Join-Path -Path $sourceFolder -ChildPath $outputFileName

                # Erstelle ein FileStream-Objekt für die .gz-Datei # Create a FileStream object for the .gz file
                $fileStream = [System.IO.File]::OpenRead($gzFile.FullName) # Optional: Wenn schon vorhanden, Zahl an Namen anhängen

                # Erstelle ein GZipStream-Objekt für die Dekomprimierung # Create a GZipStream object for decompression
                $gzipStream = [System.IO.Compression.GZipStream]::new($fileStream, [System.IO.Compression.CompressionMode]::Decompress)



                # Definiere den vollständigen Pfad zur Ausgabedatei # Define the complete path to the output file
                $outputFileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($outputFileName)
                $extension = [System.IO.Path]::GetExtension($outputFileName)
                $counter = 1
                while (Test-Path (Join-Path -Path $sourceFolder -ChildPath "$outputFileNameWithoutExtension`_$counter$extension")) {
                    $counter++
                }
                $outputFilePath = Join-Path -Path $sourceFolder -ChildPath "$outputFileNameWithoutExtension`_$counter$extension"
                $outputFileStream = [System.IO.File]::Create($outputFilePath)



                # Kopiere den Inhalt der GZip-Datei in die Ausgabedatei # Copy the content of the GZip file into the output file
                $gzipStream.CopyTo($outputFileStream)

                # Schließe die Streams # Close the streams
                $fileStream.Close()
                $outputFileStream.Close()
                $gzipStream.Close()

                # Move-Item -Path $gzFile.FullName -Destination (Join-Path -Path $processedFolderGz -ChildPath $gzFile.Name) # Wenn schon vorhanden Zahl an Namen anhängen, siehe folgenden Code # If already present, append number to name, see following code
                # Verschiebe die .gz-Datei in den processedFolderGz # Move the .gz file to the processedFolderGz
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
        Write-Output $selectedLangConfig.lang_newLogFilesFromGzArchive_noGzFilePart -ForegroundColor Yellow
    }
}

# Diese Funktion filtert Log-Dateien nach bestimmten Schlüsselwörtern und speichert die gefilterten Einträge in separaten Dateien. Anschließend werden die verarbeiteten Dateien in einen Zielordner verschoben.
# This function filters log files according to certain keywords and saves the filtered entries in separate files. The processed files are then moved to a target folder.
function New-FilteredLogs {
    param (
        [string]$outputFolder,
        [string]$processedFolder
    )

    # Prüfen, ob $outputFolder existiert # Check whether $outputFolder exists
    if (-not (Test-Path $outputFolder -PathType Container)) {
        # Erstellen des Ordners, falls er nicht existiert # Create the folder if it does not exist
        New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    }

    # Prüfen, ob $processedFolder existiert # Check whether $processedFolder exists
    if (-not (Test-Path $processedFolder -PathType Container)) {
        # Erstellen des Ordners, falls er nicht existiert # Create the folder if it does not exist
        New-Item -ItemType Directory -Path $processedFolder -Force | Out-Null
    }

    # Meldung vor dem Verarbeiten der Log-Dateien anzeigen # Display message before processing the log files
    Clear-Host
    Write-Host $selectedLangConfig.lang_processingLogsMessage -ForegroundColor Yellow
    Write-Host $selectedLangConfig.lang_pleaseWaitMessage -ForegroundColor Yellow
    Write-Host ""

    
    # Filtervorgang für jede Logdatei durchführen # Perform filter process for each log file
    foreach ($sourceFile in $sourceFiles) {
        if ($sourceFile.Extension -eq ".log") {
            # Pfad zur Log-Datei setzen # Set path to the log file
            $sourceFilePath = $sourceFile.FullName

            # Setze den Namen der Log-Datei und des Ausgabeverzeichnisses # Set the name of the log file and the output directory
            $sourceFileName = [System.IO.Path]::GetFileNameWithoutExtension($sourceFile.Name)

            # Setze den Filterzeitstempel neu # Reset the filter timestamp
            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $outputDirectory = New-Item -ItemType Directory -Path "$outputFolder\$sourceFileName`_-_gefiltert_am_$timestamp" -Force

            # Initialisiere Zähler # Initialize counter
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

            # Durchführen des Filtervorgangs und Zählen der gefundenen Schlagwörter # Execute the filter process and count the keywords found
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

            # Ausgabe der verarbeiteten Dateinamen und der Anzahl der gefundenen Schlagwörter # Output of the processed file names and the number of keywords found
            Write-Host "$($selectedLangConfig.lang_processingFinishAMessage) '$($sourceFile.Name)' $($selectedLangConfig.lang_processingFinishBMessage)" -ForegroundColor Green
            Write-Host "    $($selectedLangConfig.lang_processingFinishFolderInfoMessage):" -ForegroundColor White
            Write-Host "     - $($processedFolder)\$($sourceFileName)" -ForegroundColor Cyan

            Write-Host "    $($selectedLangConfig.lang_processingFinishFoundMessage):" -ForegroundColor White
            foreach ($key in $counter.Keys) {
                Write-Host "     - `"$key`": $($counter[$key])x;" -ForegroundColor Yellow
            }
            Write-Host ""

            # Verschieben der verarbeiteten Datei in den Zielordner mit Prüfung auf vorhandene Dateinamen # Move the processed file to the target folder with check for existing file names
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





# >>>>Variablen<<<< # >>>>Variables<<<<
# Pfad zum Skriptordner # Path to the script folder
$configFolder = "MinecraftLogFilter\"
# Pfad zur Konfigurationsdatei # Path to the configuration file
$configFile = $configFolder + "config.yml"

# Liste der verfügbaren Sprachen # List of available languages
$availableLanguages = @("de", "en")
# Pfad zur Sprachkonfigurationsdatei für Deutsch # Path to the language configuration file for German
$langDEFile = $configFolder + "lang-de.yml"
# Pfad zur Sprachkonfigurationsdatei für Englisch # Path to the language configuration file for English
$langENFile = $configFolder + "lang-en.yml"

# Aktuelle Versionsnummer und Repository-Daten von GitHub zum Abrufen der Versionsnummer aus der GitHub-API # Current version number and repository data from GitHub to retrieve the version number from the GitHub API
$currentVersion = "0.0.2" # <----------- # ToDo Current Version
$repoOwner = "RaptorXilef"
$repoName = "MinecraftLogFilterScript"

# Versionsvariablen für die Konfigurationsdatei und die Sprachkonfigurationsdateien # Version variables for the configuration file and the language configuration files
$configFileVersion = "2"
$langDEFileVersion = "2"
$langENFileVersion = "2"




# >>>>Abrufen der Funktionen<<<< # >>>>Calling up the functions<<<<
# Überprüfen, ob das Modul powershell-yaml installiert ist, wenn nicht, installiere es # Check if the powershell-yaml module is installed, if not, install it
if (-not (Get-Module -Name powershell-yaml -ListAvailable)) {
    Write-Host "[DE] Das Modul 'powershell-yaml' wird benötigt um die config.yml zu lesen, welche die Filtereinstellungen enthält. Es wird jetzt installiert..." -ForegroundColor Yellow
    Write-Host "[EN] The module 'powershell-yaml' is needed to read the config.yml, which contains the filter settings. It will now be installed..." -ForegroundColor Yellow
    Install-Module -Name powershell-yaml -Force
}
# Importieren des Moduls powershell-yaml # Import the powershell-yaml module
Import-Module -Name powershell-yaml

# Überprüfen, ob das Modul Microsoft.PowerShell.Archive installiert ist, wenn nicht, installiere es # Check if the Microsoft.PowerShell.Archive module is installed, if not, install it
if (-not (Get-Module -Name Microsoft.PowerShell.Archive -ListAvailable)) {
    Write-Host "[DE] Das Modul 'Microsoft.PowerShell.Archive' wird benötigt um die LOG.gz Dateien zu lesen. Es wird jetzt installiert..." -ForegroundColor Yellow
    Write-Host "[EN] The module 'Microsoft.PowerShell.Archive' is required to read the LOG.gz files. It will now be installed..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.PowerShell.Archive -Force
}
# Importieren des System.IO.Compression-Moduls für die Arbeit mit komprimierten Dateien # Import the System.IO.Compression module for working with compressed files
Import-Module -Name Microsoft.PowerShell.Archive

# Prüfen, ob $configFolder existiert # Check whether $configFolder exists
if (-not (Test-Path $configFolder -PathType Container)) {
    $firstStartInput = $true
    Write-Host "[DE] Prüfe auf Updates. Bitte warten!" -ForegroundColor Green
    Write-Host "[EN] Check for updates. Please wait!" -ForegroundColor Green
    Write-Host ""
    Write-Host ""
    # Prüfe auf Updates, bevor das Skript das erste Mal ausgeführt wird # Check for updates before running the script for the first time
    Test-ForUpdateAvailability -firstStart $firstStartInput -currentVersion $currentVersion -repoOwner $repoOwner -repoName $repoName
    Start-Sleep -Seconds 3
    # Erstellen des Ordners, falls er nicht existiert # Create the folder if it does not exist
    New-Item -ItemType Directory -Path $configFolder -Force | Out-Null
} else {
    $firstStartInput = $false
}

# Prüfen, ob die Sprachkonfigurationsdatei für Deutsch existiert, andernfalls erstellen # Check whether the language configuration file for German exists, otherwise create it
if (-not (Test-Path $langDEFile -PathType Leaf)) {
    New-YamlLangDEFile -FilePath $langDEFile
}

# Prüfen, ob die Sprachkonfigurationsdatei für Englisch existiert, andernfalls erstellen # Check whether the language configuration file for English exists, otherwise create it
if (-not (Test-Path $langENFile -PathType Leaf)) {
    New-YamlLangENFile -FilePath $langENFile
}

# Laden der Sprachkonfiguration für Deutsch # Load the language configuration for German
$langDEConfig = Get-Content $langDEFile | ConvertFrom-Yaml
# Laden der Sprachkonfiguration für Englisch # Load the language configuration for English
$langENConfig = Get-Content $langENFile | ConvertFrom-Yaml

if ($langDEConfig.langDEConfigVersion -ne $langDEFileVersion -or $langENConfig.langENConfigVersion -ne $langENFileVersion) {
    # Aufruf der Funktion für die Aktualisierung der Sprachdateien bei nicht Übereinstimmung der Versionsnummer # Call the function for updating the language files if the version number does not match
    Update-LanguageFiles -configFolder $configFolder -langDEFile $langDEFile -langENFile $langENFile -langDEFileVersion $langDEFileVersion -langENFileVersion $langENFileVersion
    $langDEConfig = Get-Content $langDEFile | ConvertFrom-Yaml
    $langENConfig = Get-Content $langENFile | ConvertFrom-Yaml
}

# Konfigurationsdatei erstellen # Create config-file
if (-not (Test-Path $configFile -PathType Leaf)) {
    # set Language # Wähle Sprache
    $selectedLang = Select-Language -availableLanguages $availableLanguages
    New-YamlConfigFile -FilePath $configFile

    & $MyInvocation.MyCommand.Path # Skript erneut starten # Restart the script
    EXIT
}

# Laden der ausgewählten Sprachkonfiguration basierend auf der Sprache in der config.yml # Load the selected language configuration based on the language in config.yml
$config = Get-Content $configFile | ConvertFrom-Yaml
$lang = $config.lang
$selectedLangConfig = if ($lang -eq "de") { $langDEConfig } elseif  ($lang -eq "en") { $langENConfig } else {$langENConfig}

# Festlegen der Variablen für Pfade aus der Konfiguration # Define the variables for paths from the configuration
$sourceFolder = $configFolder + $config.sourceFolder
$outputFolder = $configFolder + $config.outputFolder
$processedFolder = $configFolder + $config.processedFolder
$processedFolderGz = $configFolder + $config.processedFolderGz

# Prüfen, ob $sourceFolder existiert # Check whether $sourceFolder exists
if (-not (Test-Path $sourceFolder -PathType Container)) {
    Initialize-FileProcessingFolders -sourceFolder $sourceFolder -outputFolder $outputFolder -processedFolder $processedFolder
    & $MyInvocation.MyCommand.Path # Skript erneut starten # Restart the script
    EXIT
} else {
    # Erfassen aller Dateien im $sourceFolder # Capture all files in the $sourceFolder
    $sourceFiles = Get-ChildItem -Path $sourceFolder -File
    # Filtern der Dateien, um nur diejenigen mit der Endung ".log" und ".gz" beizubehalten # Filter the files to keep only those with the extension ".log" and ".gz"
    $sourceFiles = $sourceFiles | Where-Object { $_.Extension -eq ".log" -or $_.Extension -eq ".gz" }
    if ($sourceFiles.Count -eq 0) {
        Test-FilePresenceInSourceDirectoryByExtensionLogAndGz -sourceFolder $sourceFolder
        & $MyInvocation.MyCommand.Path # Skript erneut starten # Restart the script
        EXIT
    } else {
        # Erfassen aller GZ-Dateien im $sourceFolder # Capture all GZ files in the $sourceFolder
        $sourceFiles = Get-ChildItem -Path $sourceFolder -File
        # Filtern der Dateien, um nur diejenigen mit der Endung ".log" und ".gz" beizubehalten # Filter the files to keep only those with the extension ".log" and ".gz"
        $sourceFiles = $sourceFiles | Where-Object { $_.Extension -eq ".gz" }
        
        # Filtert die Log-Dateien und gibt das Ergebnis aus # Filters the log files and outputs the result
        New-LogFilesFromGzArchive -outputFolder $outputFolder -processedFolderGz $processedFolderGz

        # Erfassen aller Log-Dateien im $sourceFolder # Capture all log files in the $sourceFolder
        $sourceFiles = Get-ChildItem -Path $sourceFolder -File
        # Filtern der Dateien, um nur diejenigen mit der Endung ".log" und ".gz" beizubehalten # Filter the files to keep only those with the extension ".log" and ".gz"
        $sourceFiles = $sourceFiles | Where-Object { $_.Extension -eq ".log" }

        New-FilteredLogs -outputFolder $outputFolder -processedFolder $processedFolder
        # Ausgabe der Abschlussmeldung # Output of the final message
        Write-Host "" -ForegroundColor White
        Write-Host $selectedLangConfig.lang_scriptFinishedMessage -ForegroundColor Red
        Write-Host ""
        Write-Host ""
        Write-Host ""
        if ($config.searchForUpdates -eq "true") {
            # Suche nach Update # Search for update
            Test-ForUpdateAvailability -firstStart $firstStartInput -currentVersion $currentVersion -repoOwner $repoOwner -repoName $repoName
        }
        [void][System.Console]::ReadKey() # Warten auf Tastendruck # Wait for button to be pressed
        & $MyInvocation.MyCommand.Path # Skript erneut starten # Restart the script
        EXIT
    }
}
EXIT