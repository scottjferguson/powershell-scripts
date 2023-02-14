try {
    # Import settings from config file
    $config = Get-Content -Raw -Path "clone-all-github-private.config" | ConvertFrom-Json

    $reposUrl = $config.Url
    $username = $config.Username
    $organization = $config.Organization
    $personalAccessToken = $config.PersonalAccessToken
    $isPullIfExists = $config.IsPullIfExists

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
    $headers = @{
        "Authorization" = ("Basic {0}" -f $base64AuthInfo)
        "Accept" = "application/json"
    }

    # Retrieve list of all repositories
    $repos = Invoke-RestMethod -Uri $reposUrl -Method Get -Headers $headers -ContentType application/json

    $repos.ForEach({

        $repoName = $_.name
        $repoUrl = "https://{0}@github.com/{1}/{2}.git" -f $personalAccessToken, $organization, $repoName

        $projectDirectory = get-location

        if (!(Test-Path -Path $repoName)) {
            Write-Host "Cloning" $repoName -ForegroundColor Green

            git clone $repoUrl -v
        } elseif ($isPullIfExists -eq $true) {
            Write-Host "Pulling" $repoName -ForegroundColor Yellow

            set-location $repoName
            git pull
            set-location $projectDirectory
        } else {
            Write-Host "Already exists. Skipping" $repoName -ForegroundColor Yellow
        }

    })
} catch {
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    Read-Host -Prompt "Press Enter to exit"
}

Write-Host ""
read-host "Press ENTER to exit"