# INSTRUCTIONS:
# To generate the client using this script you should:
#   1. Clone the azure-rest-api-specs repo. 
#   2. Copy the script into the root directory of the azure-rest-api-specs folder.
#   3. Copy the CloudError.cs file from ArmClient.Utils folder in ASI-Common into azure-rest-api-specs folders root directory.
#   4. Run the script from the root directory.
#   5. Generated folder can now be found at the same root directory.
# 
# PARAMETERS:
#   ApiVersionTag - corresponting API version tag as can be found here https://raw.githubusercontent.com/Azure/azure-rest-api-specs/${your-branch-here}/specification/securityinsights/resource-manager/readme.md
#   Branch - your github branch, set to main by default.
#   Common - as stated in Swagger file for example 2.0 (for example https://github.com/Azure/azure-rest-api-specs/blob/main/specification/securityinsights/resource-manager/Microsoft.SecurityInsights/preview/2021-09-01-preview/dataConnectors.json)
#   Version -  as stated in Swagger file for example v3 (for example https://github.com/Azure/azure-rest-api-specs/blob/main/specification/securityinsights/resource-manager/Microsoft.SecurityInsights/preview/2021-09-01-preview/dataConnectors.json)
#   Example usage: .\AutoGenerateClientLibraries.ps1 -ApiVersionTag 'package-preview-2021-10' -Branch 'dev-Sentinel-2021-10-01-preview' 
param([string]$ApiVersionTag='', [string]$Branch='main')  
function Get-InputFiles {
    param (
        [string]$ApiVersionTag,
        [string]$Branch 
    )
    $response = Get-Content $PSScriptRoot\specification\securityinsights\resource-manager\readme.md -Raw
    $found = $response -match "(?s)(?<='$([regex]::escape($ApiVersionTag))'\s*input-file:\s)(.*?)(?=```)"
    if ($found) {
        $result = $matches[0]
    }
    $InputFiles=$result.replace('- Microsoft.SecurityInsights', '--input-file=specification\securityinsights\resource-manager\Microsoft.SecurityInsights').replace('/','\').replace("`n"," ").replace("`r","")
    return "autorest $InputFiles --csharp --output-folder=$PSScriptRoot\Generated --namespace=Microsoft.Azure.Security.Insights.ArmClient --debug --verbose --version=2.0"
}
function Get-ApiVersionLabel {
     param (
        [string]$ApiVersionTag
    )
    $found = $ApiVersionTag -match "\d{4}-\d{2}"
    if ($found) {
        $result = $matches[0]
    }
    $isPreview = $ApiVersionTag -match "preview"
    return $(If ($isPreview) {"$result-01-preview"} Else {"$result-01"})
}
function Get-State {
    param (
        [string]$ApiVersionTag
    )
    $isPreview = $ApiVersionTag -match "preview"
    return $(If ($isPreview) {"preview"} Else {"stable"})
}

if (Test-Path -Path $PSScriptRoot\Generated\*.cs) {
    Remove-Item $PSScriptRoot\Generated\*.cs
}

if (Test-Path -Path $PSScriptRoot\Generated\Models\*.cs) {
    Remove-Item $PSScriptRoot\Generated\Models\*.cs
}

$ApiVersionLabel = Get-ApiVersionLabel -ApiVersionTag $ApiVersionTag
$res = Get-InputFiles -ApiVersionTag $ApiVersionTag -Branch $Branch

Write-Host "Invoking AutoRest with the following command: $res"
Invoke-Expression $res
# Inject the correct ApiVersion into SecurityInsights.cs file
(Get-Content $PSScriptRoot\Generated\SecurityInsights.cs) | 
    Foreach-Object {
        $_ 
        if ($_ -match "BaseUri = new System.Uri") 
        {
            "`t`t`tApiVersion = `"$ApiVersionLabel`";"
        }
    } | Set-Content $PSScriptRoot\Generated\SecurityInsights.cs
# Copy cloud error 
Copy-Item "$PSScriptRoot\CloudError.cs" -Destination "$PSScriptRoot\Generated\Models\CloudError.cs"
