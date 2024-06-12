# powershell-bulk-file-copier
This project can help you transferring large number of files reading from simple CSV file (source and target) using powershell. User can select CSV file using file dialog and the script will ask to choose log directory as well. You can enhance the code as you like.
This code was tested with 10,000 files per batch (single CSV File) but source and target were using same VLAN, hence it took approx 8 minutes. Each file was approximately 500mb. 
