# PowerShell CSV PC Inventory
This PowerShell script will collect the Date of inventory, IP and MAC address, serial number, model, CPU, RAM, total storage size, GPU(s), OS, OS build, logged in user, and the attached monitor(s) of a computer.

After it collects that information, it is outputted to a CSV file. It will first check the CSV file (if it exists) to see if the hostname already exists in the file. 

If hostname exists in the CSV file, it will overwrite it with the latest information so that the inventory is up to date and there is no duplicate information.
 It is designed to be run as a login script and/or a scheduled/immediate task run by a domain user. Elevated privileges are not required.
#  Screenshots
Here is an example of what the script will output once you've used the -c flag to consolidate all the individual inventory logs into one report:
![](https://raw.githubusercontent.com/sbirdsill/PowerShell-PC-Inventory/master/Images/Sample.png)
In Excel, I formatted the CSV file as a table so that I could filter out the data I need.

While the script is designed to be run automatically by way of a login script or a scheduled task, you can also run it manually. Here's an example of what that would look like:
![](https://raw.githubusercontent.com/sbirdsill/PowerShell-PC-Inventory/master/Images/Run.png)

If the inventory does not run successfully, it outputs errors to a log file. Here's an example of the error log file:
![](https://raw.githubusercontent.com/sbirdsill/PowerShell-PC-Inventory/master/Images/ErrorLog.png)

# Setup

1. Place the script somewhere where all users will have read and execute access to it.
3. Create a folder called "InventoryOutput" (or name it whatever you prefer, just be sure to update the path specified in the $csv variable) and ensure all users have read and write access in the folder.
4. Deploy the script to all users you need it to run on. Ensure the script is being ran by the logged on user account. Computer or SYSTEM accounts will not work.
5. As the script is ran, CSV files will begin to appear in the "InventoryOutput" folder. Each of these files contain the inventory information about the computer and user account it was run on.
6. When you are ready to consolidate all the inventory files into one report, run the script as follows:
```
      .\PowerShell-PC-Inventory.ps1 -c
```
You will be prompted to enter the full path of the "InventoryOutput" folder and the path you'd like the final report to be outputted to. 

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

### How exactly does the script work?
It works in the following order:
1. First, it collects information about the system using WMI.
2. It checks to see if the CSV file already exists. If it does, it will continue on. If it doesn't it will create it.
3. Next, it will check the CSV file to see if the system's hostname already exists. If it does, it will delete that row so that it can populate it with the latest information.
4. Lastly, it will write the latest system information to the CSV file.

### Which version of PowerShell is required?
PowerShell 3 or later is required. I tested it on Windows 7 with PowerShell 3 and Windows 10 and 11 with PowerShell 5.1 and it worked on both.

### Should I deploy the GPO as a Computer Configuration or a User Configuration?
In my testing, it has only worked under user configuration. If you managed to get it to work with computer configuration, I'm interested in hearing how you did it.

### What are the recommended ways to deploy this script?

I don't have a particular recommendation. As long as it's being ran on as the logged on user, the script will work. 

Here are some ways to deploy this script:
- A PowerShell login script GPO
- A scheduled task
- An immediate task
- Add it to shell:startup
- RMM software such as Datto or ConnectWise Automate
