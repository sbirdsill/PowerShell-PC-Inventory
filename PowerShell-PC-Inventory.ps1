param(
  [switch]$c
)

# PowerShell CSV PC Inventory Script
# PowerShell-PC-Inventory.ps1
# Version 1.3
# Last updated: Nov-14-2024
#
# This PowerShell script will collect the Date of inventory, host name, IP/MAC, username (run as user), type, serial number, model, BIOS info, CPU, RAM, storage (OS drive), GPU(s), OS and version, up time, monitor(s), and installed apps (optional) on a computer. 
# After it collects that information, it is outputted to a CSV file.
# 
# It is designed to be run as a login script and/or a scheduled/immediate task run by a domain user. Elevated privileges are not required.
# Each inventory file can be complied into one CSV file by running the -c parameter.
#
# Check for the latest version or report issues at https://github.com/sbirdsill/PowerShell-PC-Inventory
#
# IMPORTANT: 
# * Parts that may need be modified for your environment are double commented (##). The rest of the script can safely be left as is.
# * New versions of this script are not backwards-compatible with previous versions. 
# * If you have upgraded to a new version of the script, please delete or archive the CSV files outputted by the previous versions before running it.

## CSV File Location (If the CSV file doesn't exist, the script will attempt to create it. Users will need full control of the file.)
## Also, make sure to create the InventoryOutput folder the CSV files will reside in. This script will not create folders automatically.
$csv = "C:\Scripts\InventoryOutput\$env:computername-Inventory.csv"

## Error log path (Optional but recommended. If this doesn't exist, the script will attempt to create it. Users will need full control of the file.)
$ErrorLogPath = "C:\Scripts\PowerShell-PC-Inventory-Error-Log.log"

## Set the checkInstalledApps variable to 1 if you want the script to output the list of installed apps on the device.
$checkInstalledApps = 0

function ConcatenateInventory {
  # If the -c flag is specified, this function will consolidate the inventory files into a presentable report.
  # It works by concatenating the individual inventory CSV files into one CSV file, then removing any duplicate lines to prevent duplicating the headers.

  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

  # Specify the folder containing the inventory CSV files
  $csvFolderPath = Read-Host "Please specify the full path of your Inventory Output folder"

  # Specify the output file path for the inventory report
  $outputFilePath = Read-Host "Please specify the full path of where you'd like to export the final inventory report to"

  # Initialize an empty hashtable to keep track of unique rows
  $uniqueRows = @{}

  # Loop through each CSV file in the folder
  Get-ChildItem -Path $csvFolderPath -Filter *.csv | ForEach-Object {
    $csvFile = $_.FullName

    # Import the CSV file
    $data = Import-Csv -Path $csvFile

    # Loop through each row in the CSV and add it to the hashtable
    foreach ($row in $data) {
      $rowKey = $row | Out-String
      if (-not $uniqueRows.ContainsKey($rowKey)) {
        $uniqueRows[$rowKey] = $row
      }
    }
  }

  # Export the unique rows to the output CSV file
  $uniqueRows.Values | Export-Csv -Path "$outputFilePath\PowerShell-PC-Inventory-Report-$timestamp.csv" -NoTypeInformation -Force

  Write-Host "Inventory consolidation complete. The inventory report is saved to $outputFilePath\PowerShell-PC-Inventory-Report-$timestamp.csv"
  exit
}

if ($c) {
  ConcatenateInventory
}

Write-Host "Gathering inventory information..."

# Date
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Installed apps
if ($checkInstalledApps -eq 1) {
  # Get list of installed applications from registry
  $installedApps = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" `
     -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty DisplayName

  # Filter out empty entries and join them into a comma-separated list
  $appsList = ($installedApps | Where-Object { $_ -ne $null }) -join "`n "

  # Output the variable
  $appsList
} else {
  $appsList = "N/A"
}

# BIOS Version/Date
$BIOSManufacturer = Get-CimInstance -Class win32_bios | Select-Object -ExpandProperty Manufacturer
$BIOSVersion = Get-CimInstance -Class win32_bios | Select-Object -ExpandProperty SMBIOSBIOSVersion
$BIOSName = Get-CimInstance -Class win32_bios | Select-Object -ExpandProperty Name
$BIOS = Write-Output $BIOSManufacturer", "$BIOSVersion", "$BIOSName

# IP and MAC address
# Get the default route with the lowest metric
$defaultRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object -Property Metric | Select-Object -First 1
# Get the interface index for the default route
$interfaceIndex = $defaultRoute.InterfaceIndex
# Get the IP address associated with this interface
$interfaceIP = (Get-NetIPAddress -InterfaceIndex $interfaceIndex | Where-Object { $_.AddressFamily -eq "IPv4" }).IPAddress
# Get the MAC address associated with this interface
$interfaceMAC = (Get-NetAdapter -InterfaceIndex $interfaceIndex).MacAddress

# Serial Number
$SN = Get-CimInstance -Class Win32_Bios | Select-Object -ExpandProperty SerialNumber

# Model
$Model = Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model

# CPU
$CPU = Get-CimInstance -Class win32_processor | Select-Object -ExpandProperty Name

# RAM
$RAM = Get-CimInstance -Class Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | ForEach-Object { [math]::Round(($_.sum / 1GB),2) }

# Storage
$Storage = Get-CimInstance -Class Win32_LogicalDisk -Filter "DeviceID='$env:systemdrive'" | ForEach-Object { [math]::Round($_.Size / 1GB,2) }

#GPU(s)
function GetGPUInfo {
  $GPUs = Get-CimInstance -Class Win32_VideoController
  foreach ($GPU in $GPUs) {
    $GPU | Select-Object -ExpandProperty Description
  }
}

## If some computers have more than two GPUs, you can copy the lines below, but change the variable and index number by counting them up by 1.
$GPU0 = GetGPUInfo | Select-Object -Index 0
$GPU1 = GetGPUInfo | Select-Object -Index 1

# OS
$OS = Get-CimInstance -Class Win32_OperatingSystem

# Up time
# Get the last boot time of the system
$lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
# Calculate the uptime by subtracting the last boot time from the current time
$uptime = (Get-Date) - $lastBootTime
# Output the uptime in a readable format
$uptimeReadable = "{0} days, {1} hours, {2} minutes" -f $uptime.Days,$uptime.Hours,$uptime.Minutes

# Username
$Username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Monitor(s)
function GetMonitorInfo {
  # Thanks to https://github.com/MaxAnderson95/Get-Monitor-Information
  $Monitors = Get-CimInstance -Namespace "root\WMI" -Class "WMIMonitorID"
  foreach ($Monitor in $Monitors) {
    ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")
    ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
    ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
  }
}

## If some computers have more than three monitors, you can copy the lines below, but change the variable and index number by counting them up by 1.
$Monitor1 = GetMonitorInfo | Select-Object -Index 0,1
$Monitor1SN = GetMonitorInfo | Select-Object -Index 2
$Monitor2 = GetMonitorInfo | Select-Object -Index 3,4
$Monitor2SN = GetMonitorInfo | Select-Object -Index 5
$Monitor3 = GetMonitorInfo | Select-Object -Index 6,7
$Monitor3SN = GetMonitorInfo | Select-Object -Index 8

$Monitor1 = $Monitor1 -join ' '
$Monitor2 = $Monitor2 -join ' '
$Monitor3 = $Monitor3 -join ' '

# Type of computer
# Values are from https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure
$Chassis = Get-CimInstance -ClassName Win32_SystemEnclosure -Namespace 'root\CIMV2' -Property ChassisTypes | Select-Object -ExpandProperty ChassisTypes

$ChassisDescription = switch ($Chassis) {
  "1" { "Other" }
  "2" { "Unknown" }
  "3" { "Desktop" }
  "4" { "Low Profile Desktop" }
  "5" { "Pizza Box" }
  "6" { "Mini Tower" }
  "7" { "Tower" }
  "8" { "Portable" }
  "9" { "Laptop" }
  "10" { "Notebook" }
  "11" { "Hand Held" }
  "12" { "Docking Station" }
  "13" { "All in One" }
  "14" { "Sub Notebook" }
  "15" { "Space-Saving" }
  "16" { "Lunch Box" }
  "17" { "Main System Chassis" }
  "18" { "Expansion Chassis" }
  "19" { "SubChassis" }
  "20" { "Bus Expansion Chassis" }
  "21" { "Peripheral Chassis" }
  "22" { "Storage Chassis" }
  "23" { "Rack Mount Chassis" }
  "24" { "Sealed-Case PC" }
  "30" { "Tablet" }
  "31" { "Convertible" }
  "32" { "Detachable" }
  default { "Unknown" }
}

# Function to write the inventory to the CSV file
function OutputToCSV {
  # CSV properties
  # Thanks to https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Script-Get-beced710
  Write-Host "Adding inventory information to the CSV file..."
  $infoObject = New-Object PSObject
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Date Collected" -Value $Date
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Hostname" -Value $env:computername
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "IP Address" -Value $interfaceIP
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "MAC Address" -Value $interfaceMAC
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "User" -Value $Username
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Type" -Value $ChassisDescription
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Serial Number/Service Tag" -Value $SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Model" -Value $Model
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "BIOS" -Value $BIOS
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "CPU" -Value $CPU
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "RAM (GB)" -Value $RAM
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Storage (GB)" -Value $Storage
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "GPU 0" -Value $GPU0
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "GPU 1" -Value $GPU1
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "OS" -Value $os.Caption
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "OS Version" -Value $os.BuildNumber
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Up time" -Value $uptimeReadable
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 1" -Value $Monitor1
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 1 Serial Number" -Value $Monitor1SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 2" -Value $Monitor2
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 2 Serial Number" -Value $Monitor2SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 3" -Value $Monitor3
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 3 Serial Number" -Value $Monitor3SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Installed Apps" -Value $appsList
  $infoObject
  $infoColl += $infoObject

  # Output to CSV file
  try {
    $infoColl | Export-Csv -Path $csv -NoTypeInformation
    Write-Host -ForegroundColor Green "Inventory was successfully updated!"
    exit 0
  }
  catch {
    if (-not (Test-Path $ErrorLogPath))
    {
      New-Item -ItemType "file" -Path $ErrorLogPath
      icacls $ErrorLogPath /grant Everyone:F
    }
    Add-Content -Path $ErrorLogPath -Value "[$Date] $Username at $env:computername was unable to export to the inventory file at $csv."
    throw "Unable to export to the CSV file. Please check the permissions on the file."
    exit 1
  }
}

# Just in case the inventory CSV file doesn't exist, create the file and run the inventory.
if (-not (Test-Path $csv))
{
  Write-Host "Creating CSV file..."
  try {
    New-Item -ItemType "file" -Path $csv
    icacls $csv /grant Everyone:F
    OutputToCSV
  }
  catch {
    if (-not (Test-Path $ErrorLogPath))
    {
      New-Item -ItemType "file" -Path $ErrorLogPath
      icacls $ErrorLogPath /grant Everyone:F
    }
    Add-Content -Path $ErrorLogPath -Value "[$Date] $Username at $env:computername was unable to create the inventory file at $csv."
    throw "Unable to create the CSV file. Please check the permissions on the file."
    exit 1
  }
}

# Check to see if the CSV file exists then run the script.
function Check-IfCSVExists {
  Write-Host "Checking to see if the CSV file exists..."
  $import = Import-Csv $csv
  if ($import -match $env:computername)
  {
    try {
      (Get-Content $csv) -notmatch $env:computername | Set-Content $csv
      OutputToCSV
    }
    catch {
      if (-not (Test-Path $ErrorLogPath))
      {
        New-Item -ItemType "file" -Path $ErrorLogPath
        icacls $ErrorLogPath /grant Everyone:F
      }
      Add-Content -Path $ErrorLogPath -Value "[$Date] $Username at $env:computername was unable to import and/or modify the inventory file located at $csv."
      throw "Unable to import and/or modify the CSV file. Please check the permissions on the file."
      exit 1
    }
  }
  else
  {
    OutputToCSV
  }
}

Check-IfCSVExists
