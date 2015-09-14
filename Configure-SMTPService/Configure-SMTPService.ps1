# Credit to: http://blogs.technet.com/b/bspieth/archive/2013/02/19/configure-the-iis-6-smtp-server-with-wmi-and-powershell.aspx

function Configure-SMTPService ([string]$incomingEMailDomainName, [int]$incomingEMailMaxMessageSize, [bool]$configureAliasDomain)
{
       Write-Host -Foregroundcolor White " -> Changing the start-up type of SMTP service to 'Automatic'..."
       Set-Service "SMTPSVC" -StartupType Automatic -ErrorAction SilentlyContinue
       if ($?)
       {
             Write-Host -Foregroundcolor Green " [OK] Successfully changed startup type."
       }
       else
       {
             Write-Host -Foregroundcolor Red " [Error] Unable to change startup type."
             Exit
       }
      
       Write-Host -Foregroundcolor White " -> Starting SMTP service..."
       Start-Service "SMTPSVC" -ErrorAction SilentlyContinue
      
       if ($?)
       {
             Write-Host -Foregroundcolor Green " [OK] Service successfully started."
       }
       else
       {
             Write-Host -Foregroundcolor Red " [Error] Unable to start service."
             Exit
       }
	   
	   Write-Host -Foregroundcolor White " -> Configuring virtual SMTP server..."
       try
       {
             $virtualSMTPServer = Get-WmiObject IISSmtpServerSetting -namespace "ROOT\MicrosoftIISv2" | Where-Object { $_.name -like "SmtpSVC/1" }
            
             # Set maximum message size (in bytes)
             $virtualSMTPServer.MaxMessageSize = ($incomingEMailMaxMessageSize * 1024)
            
             # Disable session size limit
             $virtualSMTPServer.MaxSessionSize = 0
            
             # Set maximum number of recipients
             $virtualSMTPServer.MaxRecipients = 0
            
             # Set maximum messages per connection
             $virtualSMTPServer.MaxBatchedMessages = 0
             $virtualSMTPServer.Put() | Out-Null
             Write-Host -Foregroundcolor Green " [OK] Successfully configured virtual SMTP server."
       }
       catch
       {
             Write-Host -Foregroundcolor Red " [Error] Unable to configure virtual SMTP server."
             Exit
       }
	   
	   #Skip to create a domain alias if false
	   if($configureAliasDomain -eq $false)
	   {
			Exit
	   }
      
       # Ascriptomatic is a great tool to explorefor exploring WMI namespace is scriptomatic:
       # http://www.microsoft.com/en-us/download/details.aspx?id=12028
      
       Write-Host -Foregroundcolor White " -> Creating incoming SMTP domain..."
      
       # First create a new smtp domain. The path 'SmtpSvc/1' is the first virtual SMTP server. If you need to modify another virtual SMTP server
       # change the path accordingly.
       try
       {
             $smtpDomains = [wmiclass]'root\MicrosoftIISv2:IIsSmtpDomain'
             $newSMTPDomain = $smtpDomains.CreateInstance()
             $newSMTPDomain.Name = "SmtpSvc/1/Domain/$incomingEMailDomainName"
             $newSMTPDomain.Put()  | Out-Null
             Write-Host -Foregroundcolor Green " [OK] Successfully created incoming email domain."
       }
       catch
       {
             Write-Host -Foregroundcolor Red " [Error] Unable to create incoming email domain."
             Exit
       }
      
       Write-Host -Foregroundcolor White " -> Configuring incoming SMTP domain..."
      
       try
       {
             # Configure the new smtp domain as alias domain
             $smtpDomainSettings = [wmiclass]'root\MicrosoftIISv2:IIsSmtpDomainSetting'
             $newSMTPDomainSetting = $smtpDomainSettings.CreateInstance()
 
             # Set the type of the domain to "Alias"
             $newSMTPDomainSetting.RouteAction = 16
 
             # Map the settings to the domain we created in the first step
             $newSMTPDomainSetting.Name = "SmtpSvc/1/Domain/$incomingEMailDomainName"
             $newSMTPDomainSetting.Put() | Out-Null
             Write-Host -Foregroundcolor Green " [OK] Successfully configured incoming email domain."
       }
       catch
       {
             Write-Host -Foregroundcolor Red " [Error] Unable to configure incoming e-mail domain."
             Exit
       }
       
}

Configure-SMTPService "$env:computername.$env:userdnsdomain" 30720 $false #30MB 