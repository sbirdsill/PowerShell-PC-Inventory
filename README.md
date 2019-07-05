# PowerShell CSV PC Inventory
This PowerShell script will collect the Date of inventory, IP and MAC address, serial number, model, CPU, RAM, total storage size, GPU(s), OS, OS build, logged in user, and the attached monitor(s) of a computer.

After it collects that information, it is outputted to a CSV file. It will first check the CSV file (if it exists) to see if the hostname already exists in the file. 

If hostname exists in the CSV file, it will overwrite it with the latest information so that the inventory is up to date and there is no duplicate information.
 It is designed to be run as a login script and/or a scheduled/immediate task run by a domain user. Elevated privileges are not required.
#  Screenshots
Here is an example of what the script will output:
![](https://raw.githubusercontent.com/sbirdsill/PowerShell-PC-Inventory/master/Images/Sample.png)
In Excel, I formatted the CSV file as a table so that I could filter out the data I need.

While the script is designed to be run automatically by way of a login script or a scheduled task, you can also run it manually. Here's an example of what that would look like:
![](https://raw.githubusercontent.com/sbirdsill/PowerShell-PC-Inventory/master/Images/Run.png)

If the inventory does not run successfully, it outputs errors to a log file. Here's an example of the error log file:
![](https://raw.githubusercontent.com/sbirdsill/PowerShell-PC-Inventory/master/Images/ErrorLog.png)

# Setup
By default, the CSV file and error log is set to write to the current working directory ($pwd), but it's recommended that you set this value to a location where all users will have full control over the CSV file.

If the CSV file does not exist, the script will attempt to create it and set the required permissions on it automatically, however it's recommended that you first create the CSV file (Inventory.csv by default) manually and ensure the proper permissions are set on it.

Here are some ways to deploy this script:
- A PowerShell login script GPO
- A scheduled task
- An immediate task
- Add it to shell:startup

# Potential Q&A's
### What if I have more than two GPUs or more than three monitors?
The script can easily be modified to accommodate this.

For example, if you have three GPUs, simply modify that part of the script to contain the following:

      $GPU0 = GetGPUInfo | Select-Object -Index 0
      $GPU1 = GetGPUInfo | Select-Object -Index 1
      $GPU2 = GetGPUInfo | Select-Object -Index 2

And add the following to the OutputToCSV function part of the script:

    Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "GPU 1" -Value $GPU1

The same logic applies to the monitor part of the script. If you have four monitors, add the following:

    $Monitor4 = GetMonitorInfo | Select-Object -Index 9,10
    $Monitor4SN = GetMonitorInfo | Select-Object -Index 11
    ...
    $Monitor4 = $Monitor4 -join ' '
    ...
	Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 4" -Value $Monitor4
    Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 4 Serial Number" -Value $Monitor4SN

### Some systems are reporting errors, but the inventory file has full control enabled
This is likely caused by another system that is running the inventory at the same time, causing the CSV file to be locked for editing. It shouldn't be a concern as long as the system has an opportunity to run the script again.

### How exactly does the script work?
It works in the following order:
- First, it collects information about the system using WMI.
- It checks to see if the CSV file already exists. If it does, it will continue on. If it doesn't it will create it.
- Next, it will check the CSV file to see if the system's hostname already exists. If it does, it will delete that row so that it can populate it with the latest information.
- Lastly, it will write the latest system information to the CSV file.

### Which version of PowerShell is required?
PowerShell 3 or later is required. I tested it on Windows 7 with PowerShell 3 and Windows 10 with PowerShell 5.1 and it worked on both.

### Should I deploy the GPO as a Computer Configuration or a User Configuration?
In my testing, it has only worked under user configuration. If you managed to get it to work with computer configuration, I'm interested in hearing how you did it.
