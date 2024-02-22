function CheckIfUpdateIsAvailable {
    param (
        [string]$currentVersion = "0.0.2-alpha",
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
            return $versionSurfixValueAsNumber
        }
    }

    # Definition der Funktion CheckForUpdate zum Ausgeben, ob ein Update verfügbar ist, oder nicht. # Definition of the CheckForUpdate function to output whether an update is available or not.
    function Test-UpdateAvailableWithoutConfig($currentVersion, $lastVersion, $repoOwner, $repoName) {
        $releaseUrl = "https://github.com/$repoOwner/$repoName/releases/latest"
        if ($lastVersion) {
            if (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -eq $lastVersionSurfixValueAsNumber) -or (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -gt $lastVersionSurfixValueAsNumber) -or ($currentVersion -gt $lastVersion))) {
                Write-Host "[DE] Die installierte Version: $currentVersion ($currentVersionSurfix) ist auf dem neuesten Stand." -ForegroundColor Green
                Write-Host "[EN] The installed version: $currentVersion ($currentVersionSurfix) is up to date." -ForegroundColor Green
            
            } elseif (($currentVersion -eq $lastVersion -and $currentVersionSurfixValueAsNumber -lt $lastVersionSurfixValueAsNumber) -or ($currentVersion -lt $lastVersion)) {
                Write-Host "[DE] Es ist ein Update verfügbar!" -ForegroundColor Yellow
                Write-Host "[DE] Installierte Version: $currentVersion ($currentVersionSurfix), Neueste Version: $lastVersion ($lastVersionSurfix)"
                Write-Host "[DE] Möchten Sie die Downloadseite zur letzten Version in Ihrem Browser öffnen? (J/N)"
                Write-Host "[EN] An update is available!" -ForegroundColor Yellow
                Write-Host "[EN] Installed version: $currentVersion ($currentVersionSurfix), Latest version: $lastVersion ($lastVersionSurfix)"
                $answer = Read-Host "Would you like to open the download page for the latest version in your browser? (Y/N)"

                if ($answer -eq "J" -or $answer -eq "j") {
                    Start-Process $releaseUrl
                }
                else {
                    Write-Host "[DE] Öffnen Sie die Seite $releaseUrl, um das neueste Update anzuzeigen."
                    Write-Host "[DE] Sie können auch die Suche nach Updates in der $configFile deaktivieren."
                    Write-Host "[DE] Drücken Sie eine beliebige Taste, um fortzufahren ..."
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

# Abrufen der Funktionen
CheckIfUpdateIsAvailable

PAUSE