function RenameDirectory ($item, $find, $replace) {
    try {
      $newName = $item.Name.Replace($find, $replace)
      Rename-Item $item.FullName -NewName $newName -ErrorAction Stop
    }
    catch 
    {
        Write-Host "An error occurred in RenameDirectory:" -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
    }
  }

try {
    $rootDirectory = get-location
    Get-ChildItem -Directory -Recurse -Path $rootDirectory | % { RenameDirectory $_ '%20' ' ' }
} catch {
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

Write-Host ""
Read-Host "Press ENTER to exit"