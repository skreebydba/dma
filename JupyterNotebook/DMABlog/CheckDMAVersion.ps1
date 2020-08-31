$url = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=53595';
$page = Invoke-WebRequest -Uri $url -UseBasicParsing;
$titlestart = $page.Content.IndexOf('title') + 6;
$titleend = $page.Content.IndexOf('</title>');
$titlelength = $titleend - $titlestart;
$title = $page.Content.Substring($titlestart,$titlelength);
$versionstart = $title.IndexOf(' v') + 2;
$dmaversion = $title.Substring($versionstart, 3);

$InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
foreach($obj in $InstalledSoftware)
{
    if($obj.GetValue('DisplayName') -eq 'Microsoft Data Migration Assistant')
    {
        $currentversion = $obj.GetValue('DisplayVersion').Substring(0,3);
    }
}
$currentversion;
$dmaversion;

if($currentversion -ne $dmaversion)
{
    $exists = Test-Path -Path "C:\temp\dma.msi";

    if($exists)
    {
        Remove-Item -Path "C:\temp\dma.msi";
    }

#    $url = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=53595'
#    $page = Invoke-WebRequest -Uri $url -UseBasicParsing
    $dmainstall = $page.Links | Where-Object {$_.href -like "*msi*"} | Select-Object -ExpandProperty href -First 1;

    Invoke-WebRequest -Uri $dmainstall -OutFile "C:\temp\dma.msi";
    Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\dma.msi /quiet';
}
else
{
    Write-Output 'Install unnecesssary'
}