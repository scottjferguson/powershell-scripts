<# 
.SYNOPSIS  
    Demonstrates restoring SQL Azure databases across subscriptions using Azure Automation.
    !!! If you are looking for scrubbing your data, please go to http://codebox/DataScrubber !!!
.AUTHORS
    1. Ayush Kumar
    2. Ruchira Dutta
 
.DESCRIPTION 
    The following script will create a new server on the source subscription, create a copy of the required database, and push it to the target subscription.
     
    Dependencies 
        Connect-Azure runbook:  http://gallery.technet.microsoft.com/scriptcenter/Connect-to-an-Azure-f27a81bb   

This runbook sets up a connection to an Azure subscription. 
Requirements:  
1. Automation Certificate Asset containing the management certificate loaded to Azure 
2. Automation Connection Asset containing the subscription id and the name of the certificate   
 
.PARAMETER AzureConnectionName 
Name of the Azure Subscription defined in the Connect-Azure runbook.
 
.PARAMETER SourceServerName 
Name of the Source Server where the database resides. 
 
.PARAMETER SourceDatabase 
Name of the Source database which is to be restored. 

.PARAMETER TargetDatabase 
Name of the restored database. 
 
.PARAMETER TargetServerLoginID 
Login User ID for Target Server. 

.PARAMETER TargetServerLoginPassword 
Login User Password for Target Server. 

.PARAMETER TargetServerLocation 
Location for Target Server. 

.PARAMETER TargetSubscriptionID
Location for TargetSubscriptionID. 
#> 
    
       Param
    (   
        [Parameter(Mandatory=$true)]
        [String]
        $AzureConnectionName = 'Production',
    
        [Parameter(Mandatory=$true)]
        [String]
        $sourceServerName = 'guroo-server.database.windows.net',
     
        [Parameter(Mandatory=$true)]
        [String]
        $sourceDatabaseName = 'Account',
     
        [Parameter(Mandatory=$true)]
        [String]
        $targetdatabaseName = 'Account',
        
        [Parameter(Mandatory=$true)]  
        [PSCredential]
        $Credential ,
             
        [Parameter(Mandatory=$true)]
        [String]
        $targetServerLocation = 'South Central US',
     
        [Parameter(Mandatory=$true)]
        [String]
        $targetSubscriptionID = '03fbc679-bd6a-48ec-a35a-962418b76b0b'
    )
    
 # Get the username and password from the SQL Credential 
    $targetServerLoginID = $Credential.UserName 
    $targetServerLoginPassword = $Credential.GetNetworkCredential().Password 

 # Get the time stamp when the process starts  
    'Time of Initiation : ' 
    Get-Date  
      
    # Get the Azure connection asset that is stored in the Auotmation service based on the name that was passed into the runbook   
    $AzureConn = Get-AutomationConnection -Name $AzureConnectionName  
    if ($AzureConn -eq $null)  
    {  
        throw "Could not retrieve '$AzureConnectionName' connection asset. Check that you created this first in the Automation service."  
    }  
  
    # Get the Azure management certificate that is used to connect to this subscription  
    $Certificate = Get-AutomationCertificate -Name $AzureConn.AutomationCertificateName  
    if ($Certificate -eq $null)  
    {  
        throw "Could not retrieve '$AzureConn.AutomationCertificateName' certificate asset. Check that you created this first in the Automation service."  
    }  
  
    # Set the Azure subscription configuration  
    Set-AzureSubscription -SubscriptionName $AzureConnectionName -SubscriptionId $AzureConn.SubscriptionID -Certificate $Certificate  
  
  
    #Source Details  
    $sourceSubscriptionID = $AzureConn.SubscriptionID  
    $sourceSubscription = $AzureConnectionName  
    $certThumbprint = $certificate.Thumbprint  
  
  
    #REST Metadata DO NOT CHANGE  
    $method = "POST"  
    $headerDate = '2012-03-01'  
    $headers = @{"x-ms-version"="$headerDate"}  
    $contenttype = "application/xml"  
    $body = "<TargetSubscriptionId xmlns=`"http://schemas.microsoft.com/sqlazure/2010/12/`">" + $targetSubscriptionID + "</TargetSubscriptionId>"  
  
  
    Select-AzureSubscription -Current $sourceSubscription  
  
    $details = Get-AzureSqlDatabaseServer -ServerName $sourceServerName  
    $version = $details.Version  
    $version.Version  
    if ($version -eq '2.0')  
    {  
        #Create a new server  
        $newserver = New-AzureSqlDatabaseServer -Location $targetServerLocation -AdministratorLogin $targetServerLoginID -AdministratorLoginPassword $targetServerLoginPassword  

    }  
     
    if ($version -eq '12.0')  
    {  
        #Create a new server  
        $newserver = New-AzureSqlDatabaseServer -Location $targetServerLocation -AdministratorLogin $targetServerLoginID -AdministratorLoginPassword $targetServerLoginPassword �Version "12.0"  
 
    }  
      
    if ($version -ne '12.0' -and $version -ne '2.0')  
    {  
        throw "Your version of SQL server is not compatible"  
    }  
  
    #copy database to new server   
    Start-AzureSqlDatabaseCopy -ServerName $sourceServerName -DatabaseName $sourceDatabaseName -PartnerServer $newserver.ServerName  -PartnerDatabase $targetdatabaseName   
  
    $i = 0  
      
    do  
    {  
        Checkpoint-Workflow  
  
        $AzureConn = Get-AutomationConnection -Name $AzureConnectionName  
        if ($AzureConn -eq $null)  
        {  
            throw "Could not retrieve '$AzureConnectionName' connection asset. Check that you created this first in the Automation service."  
        }  
  
        # Get the Azure management certificate that is used to connect to this subscription  
        $Certificate = Get-AutomationCertificate -Name $AzureConn.AutomationCertificateName  
        if ($Certificate -eq $null)  
        {  
            throw "Could not retrieve '$AzureConn.AutomationCertificateName' certificate asset. Check that you created this first in the Automation service."  
        }  
  
        # Set the Azure subscription configuration  
        Set-AzureSubscription -SubscriptionName $AzureConnectionName -SubscriptionId $AzureConn.SubscriptionID -Certificate $Certificate  
        Select-AzureSubscription -Current $sourceSubscription  
  
        $check = Get-AzureSqlDatabaseCopy -ServerName $sourceServerName -PartnerServer $newserver.ServerName  
        $i = $check.PercentComplete  
    }  
    while ($i -ne $null)  
      
    #change Subscription  
    $uri = "https://management.core.windows.net:8443/" + $sourceSubscriptionID + "/services" + "/sqlservers/servers/" + $newserver.ServerName + "?op=ChangeSubscription"  
  
    if ($newserver.ServerName -ne $null) 
{ 
    Invoke-RestMethod -Uri $uri -CertificateThumbPrint $certThumbprint -ContentType $contenttype -Method $method -Headers $headers -Body $body  
  
 } 
 
else 
 { 
     throw "Could not move to '$targetSubscriptionID' as new server was not created OR the number of servers in your target subscription exceeds 6. Please contact subscription administrator" 
 } 
 
    # Get the time stamp when the process starts  
    'Time of Completion : ' 
    Get-Date 