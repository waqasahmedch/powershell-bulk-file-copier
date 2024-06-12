# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to open file selection dialog with a parent form
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

# Function to open folder selection dialog with a parent form
function Select-FolderDialog {
    param (
        [string]$InitialDirectory
    )
    
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    #$FolderBrowserDialog.ShowHelp = $true
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

# Select the CSV file
$csvFilePath = Select-FileDialog
if (-not $csvFilePath) {
    Write-Host "No CSV file selected. Exiting."
    exit
}

# Get the directory of the selected CSV file
$csvDirectory = [System.IO.Path]::GetDirectoryName($csvFilePath)

# Select the log file directory and setting initial directory same as csv file
$logDirectoryPath = Select-FolderDialog -InitialDirectory $csvDirectory
if (-not $logDirectoryPath) {
    Write-Host "No log directory selected. Exiting."
    exit
}

# Create the log file name based on the CSV file name
$csvFileName = [System.IO.Path]::GetFileNameWithoutExtension($csvFilePath)
$logFileName = "${csvFileName}_log.txt"
$logFilePath = [System.IO.Path]::Combine($logDirectoryPath, $logFileName)


# Define the path to the CSV file
#$csvFilePath = "C:\powershell\TLG-Files\file_1_in_0_10000.csv"

# Define the path to the log file
#$logFilePath = "C:\powershell\TLG-Files\file_1_in_0_10000_log.txt"

# Read the CSV file
$files = Import-Csv -Path $csvFilePath

# Create the log file if it doesn't exist
if (-Not (Test-Path $logFilePath)) {
    New-Item -ItemType File -Path $logFilePath
    write-output "Log file created: $logFilePath"
}


# Read the log file into a hash table for fast lookups
$logHashTable = @{}
if (Test-Path $logFilePath) {
    Get-Content -Path $logFilePath | ForEach-Object { $logHashTable[$_] = $true }
}

$filesCopiedCount=0

# Record the start time 
$startTime = Get-Date
Add-Content -Path $logFilePath -Value "Copy process for csv file ($csvFilePath) started at: $startTime"

# Loop through each file entry in the CSV
foreach ($file in $files) {


    $sourcePath = "Y:"+ $file.source #csv file contains first \ already
    $destinationPath = "Z:"+ $file.target #csv file contains first \ already



    #increment loop counter variable
    $filesCopiedCount++

    #Write-Output $sourcePath
    #Write-Output $destinationPath
    #break

   
    # Get the destination directory
    $destinationDir = Split-Path -Path $destinationPath -Parent

    # Check if the file has already been copied using the hash table
    if (-Not $logHashTable.ContainsKey($sourcePath)) {
        try {
            # Create the destination directory if it does not exist
            if (-Not (Test-Path $destinationDir)) {
                New-Item -ItemType Directory -Path $destinationDir
            }

            # Copy the file
            Copy-Item -Path $sourcePath -Destination $destinationPath -ErrorAction Stop

            # Add to the hash table to avoid future lookups
            $logHashTable[$sourcePath] = $true

            Write-Output "Copied File[$filesCopiedCount]: $sourcePath to $destinationPath"
            # Log the copied file
            Add-Content -Path $logFilePath -Value  "Copied File[$filesCopiedCount]: $sourcePath to $destinationPath"

        } catch {
            Write-Error "Failed to copy file[$filesCopiedCount]: $sourcePath to $destinationPath. Error: $_"
            #break
            Add-Content -path $logFilePath -value "Failed to copy file[$filesCopiedCount]: $sourcePath to $destinationPath. Error: $_"
        }
    } else {
        Write-Output "Already copied: $sourcePath"
        Add-Content -path $logFilePath -value "Already copied File []: $sourcePath"
    }
}

# Record the end time
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
