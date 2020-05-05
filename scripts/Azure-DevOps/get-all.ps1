# Read configuration file
Get-Content "get-all.config" | foreach-object -begin {$h=@{}} -process { 
    $k = [regex]::split($_,'='); 
    if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { 
        $h.Add($k[0], $k[1]) 
    } 
}
$baseUrl = $h.Get_Item("Url")
$username = $h.Get_Item("Username")
$personalAccessToken = $h.Get_Item("PersonalAccessToken")

# Retrieve list of all repositories
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
$headers = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept" = "application/json"
}

$projectsUrl = "$baseUrl/_apis/projects?api-version=4.0"
$projects = Invoke-RestMethod -Uri $projectsUrl -Method Get -Headers $headers -ContentType application/json

Write-Host "Project count found: " $projects.count -ForegroundColor Green
$rootDirectory = get-location

$projects.value.ForEach({

    $projectName = $_.name

    set-location $rootDirectory

    if (!(test-path $projectName)) {
        New-Item -ItemType Directory -Force -Path $projectName
    }

    $reposUrl = "$baseUrl/$projectName/_apis/git/repositories?api-version=4.0"
    $repos = Invoke-RestMethod -Uri $reposUrl -Method Get -Headers $headers -ContentType application/json

    Write-Host "Processing " $projectName -ForegroundColor Green
    set-location $projectName

    $repos.value.ForEach({

        $repoName = $_.name
        $repoUrl = $_.remoteUrl
        $projectDirectory = get-location

        if (!(Test-Path -Path $repoName)) {
            Write-Host "Cloning " $repoName -ForegroundColor Green

            git clone $repoUrl --branch master --single-branch
        } else {
            Write-Host "Pulling " $repoName -ForegroundColor Yellow

            set-location $repoName
            git pull
            set-location $projectDirectory
        }
    })
})