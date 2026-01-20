# PowerShell CSV PC Inventory
This PowerShell script will collect the Date of inventory, host name, IP/MAC, username (run as user), type, serial number, model, BIOS info, CPU, RAM, storage (OS drive), GPU(s), OS and version, up time, monitor(s), and installed apps on a computer. 

After it collects that information, it is outputted to a CSV file. The -c parameter gives you the option to consolidate all CSV files into one CSV file, resulting in a presentable report.

It is designed to be run as a login script and/or a scheduled/immediate task run by a domain user. Elevated privileges are not required.

#  Screenshots
Here is an example of what the script will output once you've used the -c flag to consolidate all the individual inventory logs into one report:
![](https://raw.githubusercontent.com/sbirdsill/PowerShell-PC-Inventory/master/Images/Sample.png)
In Excel, I formatted the CSV file as a table so that I could filter out the data I need.

While the script is designed to be run automatically by way of a login script or a scheduled task, you can also run it manually. Here's an example of what that would look like:
![image](https://github.com/user-attachments/assets/9745edbf-d664-44a1-b58c-d3b4a3434514)

If the inventory does not run successfully, it outputs errors to a log file. Here's an example of the error log file:
![](https://raw.githubusercontent.com/sbirdsill/PowerShell-PC-Inventory/master/Images/ErrorLog.png)

# Setup

1. Place the script somewhere where all users will have read and execute access to it.
2. Create a folder called "InventoryOutput" (or name it whatever you prefer, just be sure to update the path specified in the $csv variable) and ensure all users have read and write access in the folder.
3. Deploy the script to all users you need it to run on. Ensure the script is being ran by the logged on user account. Computer or SYSTEM accounts will not work.
4. As the script is ran, CSV files will begin to appear in the "InventoryOutput" folder. Each of these files contain the inventory information about the computer and user account it was run on.
5. When you are ready to consolidate all the inventory files into one report, run the script as follows:
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
1. First, it collects information about the system using CIM.
2. It will output the collected information to a CSV file.
3. If it is run again, it will replace its old CSV file (identified by the hostname identified in the file name) with a new one.
4. After some time has elapsed, and all devices have had a chance to populate the output folder with their inventory files, you may run the -c parameter to consolidate all CSV files into one report.

### Which version of PowerShell is required?
I have only tested it on Windows 11 running PowerShell 5.1 (previous versions were tested with Windows 7 and 10). I am open to feedback if you are able or unable to get it to run on different versions.

### Should I deploy the GPO as a Computer Configuration or a User Configuration?
Deploy it as a User Configuration.

### What are the recommended ways to deploy this script?

I don't have a particular recommendation. As long as it's being ran on as the logged on user and the user has read/write access to the output folder, the script will work. 

Here are some ways to deploy this script:
* A PowerShell login script GPO
* A scheduled or immediate task
* Add it to shell:startup
* RMM software such as Datto or ConnectWise Automate
* MDM service such as Intune

 ### Contributions / Support

Your contributions to improve the script are most certainly welcome, so feel free to make a pull request if you have anything to add. The design philosophy is to make it easy to run "out of the box" for admins with limited scripting experience or time (I'm sure we can all relate to that last one). If your contributions maintain that criteria, I'm happy to merge it. If you discovered a bug, have a feature request or need assistance with the script, feel free to open an Issue and I will do my best to help. Support is provided on a "best effort, use at your own risk" basis.
