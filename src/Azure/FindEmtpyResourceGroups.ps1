#Get list of Azure Subscription ID's
$Subs = (get-AzureRMSubscription).ID

#Loop through the subscriptions to find all empty Resource Groups and store them in $EmptyRGs
foreach ($sub in $Subs)
{
    Select-AzureRmSubscription -SubscriptionId $Sub
    $AllRGs = (Get-AzureRmResourceGroup).ResourceGroupName
    $UsedRGs = (Get-AzureRMResource | Group-Object ResourceGroupName).Name
    $EmptyRGs = $AllRGs | Where-Object {$_ -notin $UsedRGs}

    #Loop through the empty Resorce Groups and print them.
    foreach ($EmptyRG in $EmptyRGs)
    {
        Write-Host $EmptyRG 
    }
}