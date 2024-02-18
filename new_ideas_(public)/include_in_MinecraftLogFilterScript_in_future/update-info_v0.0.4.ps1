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
