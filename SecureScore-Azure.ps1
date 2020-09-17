#@Author: Rachid Moyse Polania
#Ensure it's runnig like administrator the next two line
######INSTALL THE AZURERM MODULE AND RUN THE EXECUTION POLICY COMMAND######
#Install-Module azurerm
#Set-ExecutionPolicy Unrestricted
###########################################################################

#Replace the "subscription1Name" for the name of subscription 
#Replace the "subscription1ID" for the ID of the subscription
#Apply the same work for others subscriptions
$Subscriptions = @{
    "subscription1Name" = "subscription1ID"
    "subscription2Name" = "subscription2ID"
    "subscription3Name" = "subscription3ID"
}

$output = @()
###########################Using prompt authentication#####################
$username = "username" #Replace This
$password = ConvertTo-SecureString "password" -AsPlainText -Force #Replace This
$credenciales = New-Object System.Management.Automation.PSCredential($username, $password)
Connect-AzureRmAccount -Credential $credenciales
###########################################################################


$ErrorActionPreference = 'Stop'
 
if (-not (Get-Module AzureRm.Profile)) {
    Import-Module AzureRm.Profile
}
$azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
if (-not $azureRmProfile.Accounts.Count) {
        Write-Error "Ensure you have logged in before calling this function."
}
$currentAzureContext = Get-AzureRmContext
if(!$currentAzureContext){
    Write-Error "Ensure you have logged in before calling this function."
}
 
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
Write-Debug ("Getting access token for tenant" + $currentAzureContext.Subscription.TenantId)
$token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId)

$check = Test-Path ".\test-SecureScoresECP.csv"
if($check -eq $false){
    $headers = "Fecha" + "," + "Max Score" + "," + "Current Score" + "," + "SubscriptionsID" + "," + "SubscriptionsName" | Out-File -Append ".\SecureScoresECP.csv"
    Write-Host "Se crearon los Headers!"
}

foreach($subcription in $Subscriptions.GetEnumerator()){
     $id = $subcription.Value
     $name = $subcription.Name
     
     $request = Invoke-WebRequest -Method Get -Uri "https://management.azure.com/subscriptions/$id/providers/Microsoft.Security/SecureScores?api-version=2020-01-01-preview" -Headers @{'Authorization'="Bearer " + $token.AccessToken}
     $request.Content
     echo "================================================================================================================================"
    
     $date = Get-Date -Format "MM/dd/yyyy HH:mm"
     $scores = $request.Content.Split("{}")
     $onlyScores = $scores[4].Split(":")

     $object = New-Object psobject
     $object | Add-Member NoteProperty Date $date
     $object | Add-Member NoteProperty MaxScore $onlyScores[1].Split(",")[0]
     $object | Add-Member NoteProperty CurrentScore $onlyScores[2]
     $object | Add-Member NoteProperty SubcriptionID  $request.Content.Split("/")[2]
     $object | Add-Member NoteProperty SubcriptionName $name

     
     $output += $object

}

$output | Export-Csv -Path '.\SecureScores.csv' -NoTypeInformation -Append


