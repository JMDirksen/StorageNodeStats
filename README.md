# StorageNodeStats


## Setup

- Create a Google Sheet with a sheet called 'Stats', the first row can be used for headers (like: DateTime, Hostname1, Hostname2)
- Go to Extensions &rarr; Apps Script
- Add the Code.gs file, get the Spreadsheet ID from the Google Sheets URL and put it in the Code.gs (line 2)
- Deploy the script (copy the Deployment ID)
- Put your StorageNode host names in the PowerShell script (line 1)
- Also enter the Deployment ID in the PowerShell script (line 2)
- Change the KeepDays and IntervalMinutes as needed
- Run the PowerShell script on an interval


## Usage

- You can now create a chart in the Google Sheet using the generated data
- The chart can be published to view/share the chart by URL

![image](https://github.com/JMDirksen/StorageNodeStats/assets/6774030/3663b41d-69f6-408e-9978-41c17cb5f1b6)
