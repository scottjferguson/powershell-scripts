#Get list of Azure Subscription ID's
$Subs = (get-AzureRMSubscription).ID

#Loop through the subscriptions to find all empty Resource Groups and store them in $EmptyRGs
foreach ($sub in $Subs)
{
    Select-AzureRmSubscription -SubscriptionId $Sub
    $AllRGs = (Get-AzureRmResourceGroup).ResourceGroupName
    $UsedRGs = (Get-AzureRMResource | Group-Object ResourceGroupName).Name
    $EmptyRGs = $AllRGs | Where-Object {$_ -notin $UsedRGs}

    #Loop through the empty Resorce Groups asking if you would like to delete them. And then deletes them.
    foreach ($EmptyRG in $EmptyRGs)
    {
        #$Confirmation = Read-Host "Would you like to delete $EmptyRG '(Y)es' or '(N)o'"
        #if ($Confirmation -eq "y" -or $Confirmation -eq "Yes")
        #{
            Write-Host "Deleting" $EmptyRG "Resource Group" 
            Remove-AzureRmResourceGroup -Name $EmptyRG -Force
        #} 
    }
}