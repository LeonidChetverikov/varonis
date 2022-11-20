Import-Module AzureAD -UseWindowsPowerShell


function Create-User {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $UserNumber,
        [Parameter(Mandatory=$false, Position=2)]
        [string] $groupObjectID
    )
    $message=""
    $userName = "Test User"
    $userInAAD=$userName.replace(' ','')+$UserNumber+"@"+$azureDomain
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = "<Password>"
    try {
        $User=New-AzureADUser -DisplayName "New User" -PasswordProfile $PasswordProfile -UserPrincipalName $userInAAD -AccountEnabled $true -MailNickName $userName.replace(' ','')
    }
    catch {
        Write-Host "Cannot create User"
        $message = "Cannot create User "+$userName
        customLog -CustomerId $-CustomerId -SharedKey $SharedKey -message $message
    }
    try {
        Add-AzureADGroupMember -ObjectId $groupObjectID -RefObjectId $User.ObjectID
    }
    catch {
        Write-Host "Cannot assign user to group"
        $message = "Cannot assign "+$userName+" to group "+$groupObjectID
        customLog -CustomerId $-CustomerId -SharedKey $SharedKey -message $message
    }
    $date = Get-Date
    $message = "User "+ $userName+ " added ,timestamp " + $date +" successfully"
    return 

}

function Create-Group-in-AD {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $groupName
    )


        $groupAD = New-AzureADGroup -DisplayName $groupName -MailEnabled $false -SecurityEnabled $true -MailNickName $groupName.replace(' ','')
        return $groupAD.ObjectId


}

function customLog{
    param (
        [Parameter(Mandatory=$true, Position=2)]
        [string] $message
    )    

    $Body = [pscustomobject]@{
        Requester    = $env:USERNAME
        ComputerName = $env:COMPUTERNAME
        Id           = (New-Guid).Guid
        Message      = $message
    } | ConvertTo-Json
    $StringToSign = "POST" + "`n" + $Body.Length + "`n" + "application/json" + "`n" + $("x-ms-date:" + [DateTime]::UtcNow.ToString("r")) + "`n" + "/api/logs"
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToSign)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $HMACSHA256 = New-Object System.Security.Cryptography.HMACSHA256
    $HMACSHA256.Key = $KeyBytes
    $CalculatedHash = $HMACSHA256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $Authorization = 'SharedKey {0}:{1}' -f $CustomerId, $EncodedHash
     $Uri = "https://" + $CustomerId + ".ods.opinsights.azure.com" + "/api/logs" + "?api-version=2016-04-01"
    $Headers = @{
        "Authorization"        = $Authorization;
        "Log-Type"             = "CUSTOMLOG";
        "x-ms-date"            = [DateTime]::UtcNow.ToString("r");
        "time-generated-field" = $(Get-Date)
    }
    $Response = Invoke-WebRequest -Uri $Uri -Method Post -ContentType "application/json" -Headers $Headers -Body $Body -UseBasicParsing
    if ($Response.StatusCode -eq 200) {
        Write-Information -MessageData "Logs are Successfully Stored in Log Analytics Workspace" -InformationAction Continue
    }
}


try {
    Connect-AzureAD
    $groupObjectID = Create-Group-in-AD -groupName $groupName

    $i=1
    for(;$i -le 20;$i++)
    {
        $output = Create-User -UserNumber $i -azureDomain $azureDomain -groupObjectID $groupObjectID
        customLog -CustomerId $-CustomerId -SharedKey $SharedKey -message $output
    }
}
catch {
   Write-Host "Connection to AAD cannot be established"
   customLog -CustomerId $-CustomerId -SharedKey $SharedKey -message "Connection to AAD cannot be established"
   exit 1
}

