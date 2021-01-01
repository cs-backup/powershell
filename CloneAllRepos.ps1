# https://blog.rsuter.com/script-to-clone-all-git-repositories-from-your-vsts-collection/

# Read configuration file
Get-Content "CloneAllRepos.config" | foreach-object -begin {$h=@{}} -process { 
    $k = [regex]::split($_,'='); 
    if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { 
        $h.Add($k[0], $k[1]) 
    } 
}
$url = $h.Get_Item("Url")
$username = $h.Get_Item("Username")
$password = $h.Get_Item("Password")

# Retrieve list of all repositories
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
$headers = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept" = "application/json"
}

Add-Type -AssemblyName System.Web
$gitcred = ("{0}:{1}" -f  [System.Web.HttpUtility]::UrlEncode($username),$password)

$resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/git/repositories?api-version=1.0" -f $url)
$json = convertFrom-JSON $resp.Content

# Clone or pull all repositories
$initpath = get-location
foreach ($entry in $json.value) { 
    $name = $entry.name 
    Write-Host $name

    $url = $entry.remoteUrl -replace "://", ("://{0}@" -f $gitcred)
    if(!(Test-Path -Path $name)) {
        git clone $url
	    git bundle create ("{0}.bundle" -f $name) --all
    } else {
        set-location $name
        git pull
        git bundle create ("{0}.bundle" -f $name) --all
        set-location $initpath
    }
}

# CloneAllRepos.config
# [General]
# Url=https://myproject.visualstudio.com/defaultcollection
# Username=user@domain.com
# Password=YourAccessToken

# powershell -ExecutionPolicy Bypass -File ./CloneAllRepos.ps1
