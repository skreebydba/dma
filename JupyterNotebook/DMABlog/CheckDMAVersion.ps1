$url = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=53595';
$page = Invoke-WebRequest -Uri $url -UseBasicParsing;
$titlestart = $page.Content.IndexOf('title') + 6;
$titleend = $page.Content.IndexOf('</title>');
$titlelength = $titleend - $titlestart;
$title = $page.Content.Substring($titlestart,$titlelength);
$versionstart = $title.IndexOf(' v') + 2;
$dmaversion = $title.Substring($versionstart, 3);
$path = "C:\temp\dma.msi";

$InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
foreach($obj in $InstalledSoftware)
{
    if($obj.GetValue('DisplayName') -eq 'Microsoft Data Migration Assistant')
    {
        $currentversion = $obj.GetValue('DisplayVersion').Substring(0,3);
    }
}

if($currentversion -ne $dmaversion)
{
    $exists = Test-Path -Path $path;

    if($exists)
    {
        Remove-Item -Path $path;
    }

    $dmainstall = $page.Links | Where-Object {$_.href -like "*msi*"} | Select-Object -ExpandProperty href -First 1;

    Invoke-WebRequest -Uri $dmainstall -OutFile $path;
    $arglist = "/I $path /quiet"
    Start-Process msiexec.exe -Wait -ArgumentList $arglist;
}
else
{
    Write-Output 'Install unnecesssary'
}