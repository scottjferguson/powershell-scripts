################# Azure Blob Storage - PowerShell ####################  
 
## Input Parameters  
$resourceGroupName="gap-storage"  
$storageAccName="gapstoragediag"  
$fileShareName="gap-prospects"  
$directoryPath=""  
 
## Connect to Azure Account  
Connect-AzAccount   
 
## Function to Lists directories and files  
Function GetFiles  
{  
    Write-Host -ForegroundColor Green "Lists directories and files.."    
    ## Get the storage account context  
    $ctx=(Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccName).Context  
    ## List directories  
    $directories=Get-AzureStorageFile -Context $ctx -ShareName $fileShareName -Path $directoryPath
    ## Hold all the filenames
    $filenames = ''
    ## Loop through directories  
    foreach($directory in $directories)  
    {  
        write-host -ForegroundColor Magenta " Directory Name: " $directory.Name  
        $files=Get-AZStorageFile -Context $ctx -ShareName $fileShareName -Path $directoryPath | Get-AZStorageFile  
        ## Loop through all files and display  
        foreach ($file in $files)  
        {  
            $filenames += $file.Name + [Environment]::NewLine
        }  
    }

    $filenames | out-file -filepath powershell-dump.txt -append -width 500

    ## Download the file from the Powershell window using this as the filename: powershell-dump.txt
}  
  
GetFiles   
 
## Disconnect from Azure Account  
Disconnect-AzAccount  