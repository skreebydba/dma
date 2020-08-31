$exists = Test-Path -Path "C:\temp\dma.msi";

if($exists)
{
    Remove-Item -Path "C:\temp\dma.msi";
}

$url = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=53595'
$page = Invoke-WebRequest -Uri $url -UseBasicParsing
$dmainstall = $page.Links | Where-Object {$_.href -like "*msi*"} | Select-Object -exp href;

Invoke-WebRequest -Uri $dmainstall[0] -OutFile "C:\temp\dma.msi";
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\dma.msi /quiet';
#New-Item -Path "C:\Program Files\WindowsPowerShell\Modules" -Name DataMigrationAssistant -ItemType Directory;
#Expand-Archive -Path "C:\temp\dmapowershell.zip" -DestinationPath "C:\Program Files\WindowsPowerShell\Modules\DataMigrationAssistant";