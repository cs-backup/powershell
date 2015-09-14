cd %~dp0
ECHO  Installing SMTP Components and Features
powershell.exe -ExecutionPolicy Bypass -ImportSystemModules add-windowsfeature smtp-server
powershell.exe -ExecutionPolicy Bypass -file .\Configure-SMTPService.ps1
pause