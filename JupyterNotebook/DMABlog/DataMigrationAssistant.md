<!-- Chapter Start -->
# Get the Data Migration Assistant
This code downloads the installation package for the Data Migration Assistant (DMA) and installs it. 
**NOTE: This code is optional. If you have DMA installed, you can check the version manually and download the installer.** 

```ps
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

```
<!-- Chapter Start -->

# Get DMA PowerShell Modules
Download the DMA PowerShell modules from Microsoft, extract the .zip file, and put the modules into the default PowerShell path.

```ps
$zipexists = Test-Path -Path "C:\temp\dmapowershell.zip";
$psexists = Test-Path -Path "C:\ProgramFiles\WindowsPowerShell\Modules\DataMigrationAssistant";

if($zipexists)
{
    Remove-Item -Path "C:\temp\dmapowershell.zip";
}

if($psexists)
{
    Remove-Item -Path "C:\Program Files\WindowsPowerShell\Modules\DataMigrationAssistant" -Recurse;
}

Invoke-WebRequest -Uri "https://techcommunity.microsoft.com/gxcuf89792/attachments/gxcuf89792/MicrosoftDataMigration/161/1/PowerShell-Modules2.zip" -OutFile "C:\temp\dmapowershell.zip";
New-Item -Path "C:\Program Files\WindowsPowerShell\Modules" -Name DataMigrationAssistant -ItemType Directory;
Expand-Archive -Path "C:\temp\dmapowershell.zip" -DestinationPath "C:\Program Files\WindowsPowerShell\Modules\DataMigrationAssistant";

$module = "DBATools";
$dbatools = Get-Module -Name DBATools -ListAvailable;

if(!$dbatools)
{
    Write-Output "Installing";
    Install-Module -Name $module;
}
else
{
    Write-Output "Updating";
    Update-Module -Name $module;
}

```

<!-- Chapter End -->
<!-- Chapter End -->
<!-- Chapter Start -->
# Create DMA Inventory Database
Create a database to hold the inventory of instances and databases to be evaluated by DMA

```ps
Remove-DbaDatabase -SqlInstance localhost\dev2017 -Database EstateInventory -Confirm:$false;
New-DbaDatabase -SqlInstance "localhost\dev2017" -Name EstateInventory;
```

<!-- Chapter End -->
<!-- Chapter Start -->
# Create Assessment Inventory Table
Create table to hold the instances and databases to be inventoried. 

```ps

# Create collection
 $cols = @()
 # Add columns to collection
 $cols += @{
     Name      = 'ServerName'
     Type      = 'SYSNAME'
     Nullable  = $false
 }
$cols += @{
     Name      = 'InstanceName'
     Type      = 'SYSNAME'
     Nullable  = $false
 }
$cols += @{
     Name      = 'DatabaseName'
     Type      = 'SYSNAME'
     Nullable  = $false
 }
$cols += @{
     Name      = 'SqlVersion'
     Type      = 'VARCHAR'
     MaxLength = 30
     Nullable  = $false
 }
$cols += @{
     Name      = 'AssessmentFlag'
     Type      = 'CHAR'
     MaxLength = 1
     Nullable  = $false
 }

New-DbaDbTable -SqlInstance "localhost\dev2017" -Database EstateInventory -Name DatabaseInventory -ColumnMap $cols;
```
<!-- Chapter End -->
<!-- Chapter Start -->
# Populate the Assessment Inventory Table
Create a file called instances.txt in the c:\temp folder containg the databases to be assessed.  The AssessmentFlag is set to 9 be default. To assess a database, set the AssessmentFlag to 1.

```ps
$instances = Get-Content -Path C:\temp\instances.txt;
$inventoryinstance = "localhost\dev2017";

foreach($instance in $instances)
{
    $databases = Get-DbaDatabase -SqlInstance $instance -ExcludeSystem;

    Foreach($database in $databases)
    {
        $dbrow = New-Object -TypeName psobject;
        $dbrow | Add-Member -MemberType NoteProperty -Name ServerName -Value $database.ComputerName;
        $dbrow | Add-Member -MemberType NoteProperty -Name InstanceName -Value $database.InstanceName;
        $dbrow | Add-Member -MemberType NoteProperty -Name DatabaseName -Value $database.Name;
        $dbrow | Add-Member -MemberType NoteProperty -Name SqlVersion -Value $database.Compatibility;
        $dbrow | Add-Member -MemberType NoteProperty -Name AssessmentFlag -Value 0;
        $rowobject = $dbrow | ConvertTo-DbaDataTable;
        Write-DbaDbTableData -SqlInstance $inventoryinstance -Database EstateInventory -Table DatabaseInventory -InputObject $rowobject;
    }
}
```
<!-- Chapter End -->
<!-- Chapter Start -->
# Update the AssessmentFlag Column in the DatabaseInventory Table
The step above sets the AssessmentFlag to 0. To run the DMA against a database, the AssessmentFlag needs to set to 1.  Update the $query variable below to update the flag.

```ps
$query = @"
UPDATE DatabaseInventory
SET AssessmentFlag = 1
"@

Invoke-SqlCmd -ServerInstance $inventoryinstance -Database EstateInventory -Query $query;
```
<!-- Chapter End -->
<!-- Chapter Start -->
# Run the Data Migration Assessment
The Data Migration Assistant will run against all databases with AssessmentFlag set to 1 in the DatabaseInventory table. The process will create a .json file for the assessment in the -OutputLocation path. Valid values for the -TargetPlatform parm are:
* SqlServer2012
* SqlServer2014
* SqlServer2016
* SqlServerWindows2017 
* SqlServerLinux2017
* SqlServerWindows2019
* SqlServerLinux2019 
* AzureSqlDatabase 
* ManagedSqlServer

```ps
dmaDataCollector -getServerListFrom SQLServer `
-ServerName 'localhost\dev2017' `
-DatabaseName EstateInventory `
-AssessmentName AFSDataCollector `
-TargetPlatform SqlServerLinux2019 `
-OutputLocation 'C:\temp\Results\' `
-AuthenticationMethod WindowsAuth;  
```

<!-- Chapter End -->
<!-- Chapter Start -->
# Import the DMA Results to the DMAReporting Database
This code imports the results of the DMA to SQL Server database DMAReporting.

```ps
dmaProcessor -processTo SQLServer `
-serverName 'localhost\dev2017' `
-databaseName DMAReporting `
-jsonDirectory 'C:\temp\Results\' `
-CreateDMAReporting 1 `
-CreateDataWarehouse 0; 
; 

```
<!-- Chapter End -->