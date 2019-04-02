$error.clear()
$Server = Read-Host -Prompt 'Enter Server Name'
$DatabaseName = Read-Host -Prompt 'Enter Database Name'
$UserName = Read-Host -Prompt 'Enter Windows or SQL User Name'
$Password = Read-Host -AsSecureString -Prompt 'Enter Password'

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $Password 

$ScriptPath = Read-Host -Prompt 'Enter relative path'
$windowsusername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.ToString()
$Datetime = Get-Date
$processstarttime = $Datetime.ToString("yyyyMMddHHmmssfff")
$logfile = "$ScriptPath\executionlog_$processstarttime.log"

Start-Transcript -Path $logfile
Write-Host  "Batch Execution Date   : $Datetime"
Write-Host  "Server Name            : $server" 
Write-Host  "Database Name          : $DatabaseName"
Write-Host  "User Name              : $UserName"
Write-Host  "Executed By            : $windowsusername" 
Write-Host  "Script Path            : $ScriptPath"
Write-Host  "Log File               : $logfile"
Write-Host  $("*" * 100) -ForegroundColor Cyan

$checkmodule = Get-Module -ListAvailable | Where-Object { $_.Name  -eq "dbatools"}
if (!$checkmodule) {    
    Write-Host "Installing dbatools module" -ForegroundColor Cyan
    Start-Process powershell.exe -ArgumentList "-Command Install-Module dbatools" -Verb RunAs -Wait
} elseif ($checkmodule) {
    Import-Module dbatools -Force
    Write-Host "dbatools module already exists" -ForegroundColor Green
}

if (!([System.IO.File]::Exists($ScriptPath))){
    Write-Host "$ScriptPath does not exists or the user does not have access" -ForegroundColor Red
    Break
}
               
foreach ($file in Get-ChildItem $ScriptPath -Filter "*.sql" -Recurse | Sort-Object -Property FullName) {
    try {
        Write-Host "****** PROCESSING $file FILE ******" -ForegroundColor Yellow
        Invoke-DbaQuery -SqlInstance $Server `
            -SqlCredential $Credential `
            -Database $DatabaseName `
            -File $file.FullName `
            -EnableException `
            -MessagesToOutput
        Write-Host "******SUCCESSFULLY PROCESSED $file FILE ******" -ForegroundColor Green  
        Write-Host $("*" * 100) 
                
    }
    catch {
        Write-Host "******FAILED PROCESSING $file FILE ******" -ForegroundColor Red
        Write-Host "$error[0].Exception.Message" -ForegroundColor Red
        Write-Host $("*" * 100)

    }
}
Write-Host "****** All Files Processed Successfully ******" -ForegroundColor Green
Stop-Transcript