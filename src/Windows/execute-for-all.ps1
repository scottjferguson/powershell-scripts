try {
    # Import settings from config file
    $config = Get-Content -Raw -Path "execute-for-all.config" | ConvertFrom-Json

    $dirs = Get-ChildItem -Directory
    $scriptDirectory = get-location

    foreach ($dir in $dirs) {
        set-location $dir

        foreach ($command in $config.commands) {
            Invoke-Expression $command
        }

        set-location $scriptDirectory        
    }
} catch {
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

Write-Host ""
Write-Host "Complete" -ForegroundColor Green
read-host "Press ENTER to exit"