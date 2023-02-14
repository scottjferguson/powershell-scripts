try {
    # Import settings from config file
    $config = Get-Content -Raw -Path "clone-all-github.config" | ConvertFrom-Json

    $reposUrl = $config.Url
    $isPullIfExists = $config.IsPullIfExists

    # Retrieve list of all repositories
        $repos = Invoke-RestMethod -Uri $reposUrl -Method Get -ContentType application/json

        $repos.ForEach({

            $repoName = $_.name
            $repoUrl = $_.clone_url
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