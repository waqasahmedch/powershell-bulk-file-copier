## PowerShell Script Documentation

### Purpose

This PowerShell script reads file names and their paths from a CSV file, copies those files to another location specified in the CSV, and maintains a log of copied files. It ensures that if the process is interrupted and restarted, it will only copy the remaining files. The script also tracks the start time, end time, and total time taken for the copy process.

### Features

- Select CSV file and log directory through interactive dialogs.
- Log file is created in the selected directory with a name based on the CSV file name.
- Efficiently checks and logs copied files using a hash table.
- Records start time, end time, and total time taken.
- Displays the number of files copied so far during the process.

### Usage Instructions

1. **Run the Script**: Open PowerShell and run the script.
2. **Select CSV File**: A dialog will appear asking you to select the CSV file containing the source and destination paths.
3. **Select Log Directory**: Another dialog will prompt you to select the directory where the log file should be created. The initial directory will be set to the location of the CSV file.
4. **Script Execution**: The script will then proceed to copy the files as specified in the CSV and log the operations.

### CSV File Format

The CSV file should have the following structure:

```csv
Source,target
source\file1.txt,target\file1.txt
source\file2.txt,target\file2.txt
...
```

**Note**: The paths in the CSV file can be of any type. They may start with drive letter such as "C:\folder1\file1.txt" or Network file storage (NFS) path i.e \\\networkpath\folder1\file.txt

### Script Details

#### Main Components

1. **Loading Assemblies**:
   ```powershell
   Add-Type -AssemblyName System.Windows.Forms
   Add-Type -AssemblyName System.Drawing
   ```

2. **File Selection Dialog**:
   ```powershell
   function Select-FileDialog {
       $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
       $OpenFileDialog.Filter = "CSV files (*.csv)|*.csv"
       $OpenFileDialog.ShowHelp = $true
       # Create a hidden form to make the dialog topmost
       $form = New-Object System.Windows.Forms.Form
       $form.TopMost = $true
       $form.StartPosition = "CenterScreen"
       $form.Width = 1
       $form.Height = 1
       $form.ShowInTaskbar = $false
       $form.Show()
       $form.Activate()
       $OpenFileDialog.ShowDialog($form) | Out-Null
       $form.Dispose()
       return $OpenFileDialog.FileName
   }
   ```

3. **Folder Selection Dialog**:
   ```powershell
   function Select-FolderDialog {
       param ([string]$InitialDirectory)
       $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
       $FolderBrowserDialog.SelectedPath = $InitialDirectory
       # Create a hidden form to make the dialog topmost
       $form = New-Object System.Windows.Forms.Form
       $form.TopMost = $true
       $form.StartPosition = "CenterScreen"
       $form.Width = 1
       $form.Height = 1
       $form.ShowInTaskbar = $false
       $form.Show()
       $form.Activate()
       $FolderBrowserDialog.ShowDialog($form) | Out-Null
       $form.Dispose()
       return $FolderBrowserDialog.SelectedPath
   }
   ```

4. **Selecting CSV File and Log Directory**:
   ```powershell
   $csvFilePath = Select-FileDialog
   if (-not $csvFilePath) {
       Write-Host "No CSV file selected. Exiting."
       exit
   }
   $csvDirectory = [System.IO.Path]::GetDirectoryName($csvFilePath)
   $logDirectoryPath = Select-FolderDialog -InitialDirectory $csvDirectory
   if (-not $logDirectoryPath) {
       Write-Host "No log directory selected. Exiting."
       exit
   }
   ```

5. **Log File Setup**:
   ```powershell
   $csvFileName = [System.IO.Path]::GetFileNameWithoutExtension($csvFilePath)
   $logFileName = "${csvFileName}_log.txt"
   $logFilePath = [System.IO.Path]::Combine($logDirectoryPath, $logFileName)
   ```

6. **Reading CSV and Log File**:
   ```powershell
   $files = Import-Csv -Path $csvFilePath
   if (-Not (Test-Path $logFilePath)) {
       New-Item -ItemType File -Path $logFilePath
   }
   $logHashTable = @{}
   if (Test-Path $logFilePath) {
       Get-Content -Path $logFilePath | ForEach-Object { $logHashTable[$_] = $true }
   }
   ```

7. **Copying Files**:
   ```powershell
   $filesCopiedCount = 0
   $startTime = Get-Date
   Add-Content -Path $logFilePath -Value "Copy process for csv file ($csvFilePath) started at: $startTime"
   foreach ($file in $files) {
       #if you change the source file column name in csv file from default "source" then you must update the code $file.YourNewColumn Name
       $sourcePath = $file.SourcePath
       #if you change the column target/destination column name in csv file from default "target" then you must update the code $file.YourNewColumn Name
       $destinationPath = $file.target 
       
       $destinationDir = Split-Path -Path $destinationPath -Parent

      # Here we introducted hashtable to speed up the copied files indexes, so in case of network interruption it even if you choose same 
      # Csv file, it wont copy again the files which were copied already because their index was created. 
      # Here you need to understand, i managed to create full path with file name as index, so even if the same file name is used but its path 
      # was different.

      # Check if the file has already been copied using the hash table
       if (-Not $logHashTable.ContainsKey($sourcePath)) {
           try {
               if (-Not (Test-Path $destinationDir)) {
                   New-Item -ItemType Directory -Path $destinationDir
               }
               Copy-Item -Path $sourcePath -Destination $destinationPath -ErrorAction Stop
               Add-Content -Path $logFilePath -Value $sourcePath
               # Add to the hash table to avoid future lookups
               $logHashTable[$sourcePath] = $true       
               Write-Output "Copied File[$filesCopiedCount]: $sourcePath to $destinationPath"
               # Log the copied file information.
               Add-Content -Path $logFilePath -Value  "Copied File[$filesCopiedCount]: $sourcePath to $destinationPath"
             } catch {
                  Write-Error "Failed to copy file[$filesCopiedCount]: $sourcePath to $destinationPath. Error: $_"
                  Add-Content -path $logFilePath -value "Failed to copy file[$filesCopiedCount]: $sourcePath to $destinationPath. Error: $_"
           }
       } else {
               Write-Output "Already copied: $sourcePath"
               Add-Content -path $logFilePath -value "Already copied File [$filesCopiedCount]: $sourcePath"
       }
   }
   ```

8. **Recording End Time and Total Time Taken**:
   ```powershell
   $endTime = Get-Date
   $totalTime = $endTime - $startTime
   # Log the total number of files copied and the total time taken
   Add-Content -Path $logFilePath -Value "Total files copied: $filesCopiedCount"
   Add-Content -Path $logFilePath -Value "Copy process ended at: $endTime"
   Add-Content -Path $logFilePath -Value "Total time taken: $totalTime"
   # Output the total number of files copied and the total time taken
   Write-Output "Total files copied: $filesCopiedCount"
   Write-Output "Copy process ended at: $endTime"
   Write-Output "Total time taken: $totalTime"
   ```

### Notes
- Ensure the CSV file paths are correct and the script has necessary permissions to read and write to the specified locations.
- The script creates a log file in the same directory as the CSV file by default, unless a different directory is selected.

