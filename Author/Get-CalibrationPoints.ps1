#
# script to pull in Calibration Data for the 1830s Map
#

param ($calibrationFile="P:\Users\Bill\Documents\My Stories\Bobby's Dawn\CalibrationPoints.xlsx")

cls

#region Setup
#
# The script can take hours to run on a large dataset
# We need to report progress.  For short-ish tasks, up to about 30s
# we simply need to use Write-Host to output timely status messages
#
# (we use Write-Progress to show progress of longer tasks)
#
$ScriptElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()

$lastt = 0

function reportPhaseComplete ([string]$description) {
  $t = $ScriptElapsedTime.Elapsed.TotalSeconds
  $phaset = [Math]::Floor(($t - $script:lastt) * 10) / 10
  write-host "Phase complete, taking $phaset seconds: $description"
  $script:lastt = $t
}

function reportScriptComplete ([string]$description) {
  $t = $ScriptElapsedTime.Elapsed.TotalSeconds
  $phaset = [Math]::Floor(($t) * 10) / 10
  write-host "Script complete, taking $phaset seconds: $description"
  $script:lastt = $t
}

#
# standard functions to find the directory in which the script is executing
# we'll use this info to read and write both cache files and reports
#
function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

$sdir = Get-ScriptDirectory

$infoColours = @{foreground="cyan"}
$warningColours = @{foreground="yellow"}
$errorColours = @{foreground="red"}
$debugColours = @{foreground="green"}

#endregion

#region File Management
#
# Having identified the current working directory, we can now set up paths for the
# various cache files and report files used by the script.
#
# see https://blogs.msdn.microsoft.com/koteshb/2010/02/12/powershell-how-to-find-details-of-operating-system/
#
$projectLocationFile          = "$sdir\Geospatial.js"
$BCCommandFile                = "$sdir\CopyFiles.bccommand"
$calibrationFileCsv           = "$sdir\CalibrationPoints.csv"
#endregion

..\Utilities\Generate-CsvFromXls.ps1 -ExcelFile $calibrationFile -CsvFile $calibrationFileCsv -WorksheetName "CalibrationData"

Import-Csv -LiteralPath $calibrationFileCsv
