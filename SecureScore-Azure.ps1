#@Author: Rachid Moyse Polania
#@Company: TIVIT
#Ensure it's runnig like administrator the next two lines
#Install-Module azurerm
#Set-ExecutionPolicy Unrestricted

$Subscriptions = @{
    "ECP-DevTest" = "c818ac3b-d6f3-4229-a359-0d5ac47a4317"
    "ECP-Production" = "d9e2f9de-9c3c-4a3a-93d9-1d2d5bf16fa2"
    "ECP-Shared" = "66612ed2-9774-4b1c-a226-693672d0362d"
    "Operaciones ECP" = "b2730210-6c74-49b6-9692-4da321ab7db8"
    "Portal ECOPETROL - Extranet" = "9ce752d7-bb06-412b-9ebe-514a6116e0f5"
    "Proyectos QA" = "e1a9820c-5b75-4678-9cef-c03928f58370"
    "Servicios Transversales" = "68f1b01a-d70c-49b0-9d23-03414febbba0"
    "Upstream G y G" = "edada5cf-38d9-4029-a2e8-04c6e55769d7"
}

$output = @()
###########################Using prompt authentication#####################
$username = "_SecCenOp@ecopetrol.onmicrosoft.com"
$password = ConvertTo-SecureString "hackmeplease123@." -AsPlainText -Force
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

$output | Export-Csv -Path '.\test-SecureScoresECP.csv' -NoTypeInformation -Append


