

# Declaring the parameter that to give at run time 
param (
	[string] $subscriptionId = "YourSubscription",
	[string] $resourceGroupName = "MyRG",
	[string] $location = "eastus",
	[switch] $Debug = $false
)

exit

. .\libs\sshUtils.ps1
# Sigining in to the portal
Write-Host "Logging in..."
Login-AzureRmAccount

# Getting the subsciptions from the portal
Get-AzureRmSubscription -SubscriptionId $subscriptionId

#select subscription
Write-Host "Select the subscriptions from"
Set-AzureRmContext -Subscription $subscriptionId

# Create or using existing resourceGroup 
Write-Host "Verifying ResourceGroupName exit or not: '$resourceGroupName'"
$resourcegroup = Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -erroraction silentlycontinue
if(!$resourcegroup)
{
	Write-Host "Creating ResourceGroup: '$resourceGroupName'"
	New-AzureRmResourceGroup -Name $resourceGroupName -Location $location 
}
else
{
	Write-Host "Resourcegroup: '$resourceGroupName' already exists"
}

# Deploying VM and checking whether it is succeeded or not
$name="MyUbuntuVM"
Write-Host "Creating and Deploying the VM"
$RGdeployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile "Templates\azuredeploy.json" -TemplateParameterFile "Templates\azuredeploy.parameters.json"
if ($RGdeployment.ProvisioningState -eq "Succeeded")
{
    $MaxTimeOut=300
    $i=0
    while($MaxTimeOut -gt $i)
    {
        $vmDetail=Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $name  -Status
        if($vmDetail.Statuses[0].DisplayStatus -eq  "Provisioning succeeded")
        {
			$RGdeployment			#Displaying the ssh details of the VM
            Write-Host "Deployment completed succesfully"
            break
        }
        else
        {
            Write-Host -NoNewline "." 	#print a . without newline
        }
        $i=$i+1
    }
    if ($MaxTimeOut -eq $i)
    {
        Write-Host "Deployment failed"
    } 
}

#To get the PublicIp Address of the VM that created
Write-Host "Getting the IpAddress of the VM"
if ($RGdeployment.ProvisioningState -eq "Succeeded")
{
    Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName  -Name MyPublicIp | Select-Object ResourceGroupName, Name, IpAddress
}
else
{
    Write-Host "IpAddress not found"
}
