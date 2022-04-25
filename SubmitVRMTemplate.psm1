<#
 .Synopsis
  Uploads a VRM Template to Veracity

 .Description
  Upload a template and parameter file to Veracity include Veracity in your Infrastructure as Code.

 .Parameter templatePath
  The path to the template file

 .Parameter parameterPath
  The path to the parameter file

 .Parameter projectId
  The project id from developer.veracity.com

 .Parameter accessKey
  Your IAC access key optained from developer.veracity.com

 .Parameter veracityEnvironment
  Leave in normal cases.

 .Example
   #Upload template and parameters
   Submit-VrmTemplate -templatePath 'C:\temp\template.json' -parameterPath 'C:\temp\parameters.json' -projectId '00000000-0000-0000-0000-000000000000' -accessKey 'generated-token'

#>
function Submit-VrmTemplate {
param(
    [string]$templatePath,
    [string]$parameterPath,
    [string]$format='json',
    [string]$projectId='',
    [string]$accessKey='',
    [string]$veracityEnvironment='https://api.veracity.com/developer/vrm/v1'
    )
    $headers = @{
    'Authorization' = "Bearer $($accessKey)"
}
    $url = $veracityEnvironment + "/projects/$($projectId)/resourceGroups/files" 
    $template = Get-Content -Raw -Path $templatePath 
    $parameters = Get-Content -Raw -Path $parameterPath 
    $templateBytes = [System.Text.Encoding]::UTF8.GetBytes($template)
    $templateString =[Convert]::ToBase64String($templateBytes)
    $parametersBytes = [System.Text.Encoding]::UTF8.GetBytes($parameters)
    $parametersString =[Convert]::ToBase64String($parametersBytes)
    $payload = @{format=$format;template=$templateString;parameters=$parametersString} | ConvertTo-Json
    Write-Host -ForegroundColor yellow "`nSubmitting template..."
    try {
        $response = Invoke-RestMethod $url -Method Post -Body $payload -Headers $headers -ContentType 'application/json'
        $bytes=[Convert]::FromBase64String($response)
        $json=[System.Text.Encoding]::UTF8.GetString($bytes)
        Write-Host -ForegroundColor green "Response:"
        Write-Output $json | ConvertFrom-Json | ConvertTo-Json -Depth 5
    }
    catch {
        Write-Host -ForegroundColor red "Error:"
        Write-Output (ParseErrorResponse($_) | ConvertFrom-Json | ConvertTo-Json -Depth 5 )
    }
}

# Helper function to support Powershell older than version 6
function ParseErrorResponse($result) {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        if ($result.Exception.Response) {  
            $streamReader = New-Object System.IO.StreamReader($result.Exception.Response.GetResponseStream())
            $streamReader.BaseStream.Position = 0
            $streamReader.DiscardBufferedData()
            $content = $streamReader.ReadToEnd()
            return $content
        }
    }
    else {
        return $result.ErrorDetails.Message
    }
}

Export-ModuleMember -Function Submit-VrmTemplate
