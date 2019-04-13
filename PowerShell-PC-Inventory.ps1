# PowerShell CSV PC Inventory Login Script
# PowerShell-PC-Inventory.ps1
# Version 1.0
# Last updated: 11/26/2018
#
# This PowerShell script will collect the Date, IP, Serial Number, Model, CPU, RAM, Storage, OS and OS Build of a computer. It will then output it into a CSV file.
# Before it does that, it will check the CSV file to see if the hostname is already in the file. If it is, it will exit the script. Otherwise, it will log the information.
# It is designed to be run as a login script/immediate task run by a domain user. Elevated privileges are not required.
#
# IMPORTANT: Parts that will need be modified for your environment are double commented (##). The rest can safely be left alone.

## CSV File Location (remember to allow Write permissions for the "Everyone" or "Domain Users" group)
$csv = "$pwd\Inventory.csv"

# Date
$Date = Get-Date -Format yyyy-MM-dd

# IP
$IP = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway -ne $null }).IPAddress | Select-Object -First 1

# Serial Number
$SN = Get-WmiObject -Class Win32_Bios | Select-Object -ExpandProperty SerialNumber

# Model
$Model = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model

# CPU
$CPU = Get-WmiObject -Class win32_processor | Select-Object -ExpandProperty Name

# RAM
$RAM = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | ForEach-Object { [math]::Round(($_.sum / 1GB),2) }

# Storage
$Storage = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" | ForEach-Object { [math]::Round($_.Size / 1GB,2) }

# OS
$OS = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption

# OS Build
$OSBuild = (Get-Item "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('ReleaseID')

# Function to write the inventory to the CSV file
function inventory {
  # CSV properties
  # https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Script-Get-beced710
  $infoObject = New-Object PSObject
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Date Collected" -Value $Date
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "IP" -Value $IP
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Hostname" -Value $env:computername
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "User" -Value $env:UserName
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Serial Number/Service Tag" -Value $SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Model" -Value $Model
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "CPU" -Value $CPU
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "RAM (GB)" -Value $RAM
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Storage (GB)" -Value $Storage
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "OS" -Value $OS
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "OS Version" -Value $OSBuild
  $infoObject
  $infoColl += $infoObject

  # Output to CSV file
  $infoColl | Export-Csv -Path $csv -NoTypeInformation -Append
}

# Just in case the inventory CSV file doesn't exist, go ahead and create the file and run the inventory.
if (-not (Test-Path $csv))
{
  inventory
}

# First, verify and check to see if the S/N of the machine is already in the inventory. If it is, exit the script, othwerise run the inventory.
function Verify {
  $import = Import-Csv $csv
  if ($import -match $env:computername)
  {
    break
  }
  else
  {
    inventory
  }
}

Verify
