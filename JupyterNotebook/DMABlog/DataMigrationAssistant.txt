<#
    Created from: .\DataMigrationAssistant.ipynb

    Created by: Export-NotebookToPowerShellScript
    Created on: 08/26/2020 12:29:37    
#>

<# # Chapter 1 #>

<# # Get Data Migration Assistant PowerShell Modules
This code downloads a .zip file from Microsoft containing the PowerShell modules for DMA.  Once downloaded, it is extracted to folder C:\Program Files\WindowsPowerShell\Modules\DataMigrationAssistant

 #>

Invoke-WebRequest -Uri "https://techcommunity.microsoft.com/gxcuf89792/attachments/gxcuf89792/MicrosoftDataMigration/161/1/PowerShell-Modules2.zip" -OutFile "C:\temp\dmapowershell.zip";
New-Item -Path "C:\Program Files\WindowsPowerShell\Modules" -Name DataMigrationAssistant -ItemType Directory;
Expand-Archive -Path "C:\temp\dmapowershell.zip" -DestinationPath "C:\Program Files\WindowsPowerShell\Modules\DataMigrationAssistant";


<# 
 #>

<# # Chapter 2 #>

<# # Create DMA Inventory Database
Create a database to hold the inventory of instances and databases to be evaluated by DMA

 #>

Remove-DbaDatabase -SqlInstance localhost\dev2017 -Database EstateInventory -Confirm:$false;
New-DbaDatabase -SqlInstance "localhost\dev2017" -Name EstateInventory;


<# 
 #>

<# # Chapter 3 #>

<# # Create Assessment Inventory Table
Create table to hold the instances and databases to be inventoried. 

 #>


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


<# # Chapter 4 #>

<# # Populate the Assessment Inventory Table
Create a file called instances.txt in the c:\temp folder containg the databases to be assessed.  The AssessmentFlag is set to 9 be default. To assess a database, set the AssessmentFlag to 1.

 #>

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


<# # Chapter 5 #>

<# # Update the AssessmentFlag Column in the DatabaseInventory Table
The step above sets the AssessmentFlag to 0. To run the DMA against a database, the AssessmentFlag needs to set to 1.  Update the $query variable below to update the flag.

 #>

$query = @"
UPDATE DatabaseInventory
SET AssessmentFlag = 1
WHERE SqlVersion = N'Version140'
"@

Invoke-SqlCmd -ServerInstance $inventoryinstance -Database EstateInventory -Query $query;


<# # Chapter 6 #>

<# # Run the Data Migration Assessment
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

 #>

dmaDataCollector -getServerListFrom SQLServer `
-ServerName 'localhost\dev2017' `
-DatabaseName EstateInventory `
-AssessmentName AFSDataCollector `
-TargetPlatform SqlServerLinux2019 `
-OutputLocation 'C:\temp\Results\' `
-AuthenticationMethod WindowsAuth;  


<# 
 #>

<# # Chapter 7 #>

<# # Import the DMA Results to the DMAReporting Database
This code imports the results of the DMA to SQL Server database DMAReporting.

 #>

dmaProcessor -processTo SQLServer `
-serverName 'localhost\dev2017' `
-databaseName DMAReporting `
-jsonDirectory 'C:\temp\Results\' `
-CreateDMAReporting 1 `
-CreateDataWarehouse 0; 



