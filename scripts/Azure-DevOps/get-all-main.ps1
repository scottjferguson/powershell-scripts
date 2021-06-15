try {
    # Import settings from config file
    $config = Get-Content -Raw -Path "get-all.config" | ConvertFrom-Json

    $baseUrl = $config.Url
    $username = $config.Username
    $personalAccessToken = $config.PersonalAccessToken
    $isPullIfExists = $config.IsPullIfExists

    # Retrieve list of all repositories
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
    $headers = @{
        "Authorization" = ("Basic {0}" -f $base64AuthInfo)
        "Accept" = "application/json"
    }

    $projectsUrl = "$baseUrl/_apis/projects?api-version=4.0"
    $projects = Invoke-RestMethod -Uri $projectsUrl -Method Get -Headers $headers -ContentType application/json

    Write-Host "Project count found:" $projects.count -ForegroundColor Green
    $rootDirectory = get-location

    $projects.value.ForEach({

        $projectName = $_.name

        set-location $rootDirectory

        if (!(test-path $projectName)) {
            New-Item -ItemType Directory -Force -Path $projectName
        }

        $reposUrl = "$baseUrl/$projectName/_apis/git/repositories?api-version=4.0"
        $repos = Invoke-RestMethod -Uri $reposUrl -Method Get -Headers $headers -ContentType application/json

        Write-Host ""
        Write-Host "Processing" $projectName -ForegroundColor Green
        set-location $projectName

        $repos.value.ForEach({

            $repoName = $_.name
            $repoUrl = $_.remoteUrl
            $projectDirectory = get-location

            if (!(Test-Path -Path $repoName)) {
                Write-Host "Cloning" $repoName -ForegroundColor Green

                try {
                    git clone $repoUrl --branch main --single-branch -q
                } catch {
                    Write-Warning $Error[0]
                }                
            } elseif ($isPullIfExists -eq $true) {
                Write-Host "Pulling" $repoName -ForegroundColor Yellow

                set-location $repoName
                git pull
                set-location $projectDirectory
            } else {
                Write-Host "Already exists. Skipping" $repoName -ForegroundColor Yellow
            }

        })
    })
} catch {
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    Read-Host -Prompt "Press Enter to exit"
}

Write-Host ""
read-host "Press ENTER to exit"