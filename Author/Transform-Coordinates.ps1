#
# script to transform coordinates for 1830s Map to and from Lat/Long
# taking account of rotation
#

param ($x,$y)

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
$postcodeCacheFile         = $sdir + "\..\MappingData\PostcodeCache.xml"
#endregion

$HQ = @("Greenwich Observatory",51.476852,-0.000500)

. ..\Postcode\LocationUtilities.ps1

$referencePoints = $(.\Get-CalibrationPoints.ps1) | Where-Object { $_.Confidence -eq 0} | Sort-Object -Property @{Expression={[int]$_.x};Descending=$false}

$NSCorrection = $DegreesLongitudePer250m / $DegreesLatitudePer250m

function Scale-Side ($SideLen,$FieldName) {
  switch ($FieldName) {
    "Latitude" { $SideLen = $SideLen / $DegreesLatitudePer250m }
    "Longitude" { $SideLen = $SideLen / $DegreesLongitudePer250m }
  }
  return $SideLen
}
function Derive-ABC ($Fields,$Factor) {
   $sides = @(0,0,0)
   for ($first = 0; $first -lt $sides.Length; $first++) {
      $second = ($first + 1) % $sides.Length
      $f = $Fields[0]
      $side1 = Scale-Side -SideLen $($referencePoints[$first]."$f" - $referencePoints[$second]."$f") -FieldName $f
      $f = $Fields[1]
      $side2 = Scale-Side -SideLen $($referencePoints[$first]."$f" - $referencePoints[$second]."$f") -FieldName $f
      $hypotenuse = [math]::Sqrt([math]::Pow($side1,2) + [math]::Pow($side2,2))
      $sides[$first] = $hypotenuse
   }
   $a = $sides[0]
   $b = $sides[1]
   $c = $sides[2]
   $cosA = ([math]::Pow($b, 2) + [math]::Pow($c, 2) - [math]::Pow($a, 2)) / (2 * $b * $c)
   $Arad = [math]::Acos($cosA)
   $Adeg = $Arad * 360.0 / (2 * [math]::PI)
   Write-Host "Angle A = $Arad radians ($Adeg degrees) @ $($referencePoints[2].StationName)"
   $cosB = ([math]::Pow($a, 2) + [math]::Pow($c, 2) - [math]::Pow($b, 2)) / (2 * $a * $c)
   $Brad = [math]::Acos($cosB)
   $Bdeg = $Brad * 360.0 / (2 * [math]::PI)
   Write-Host "Angle B = $Brad radians ($Bdeg degrees) @ $($referencePoints[0].StationName)"
   $cosC = ([math]::Pow($a, 2) + [math]::Pow($b, 2) - [math]::Pow($c, 2)) / (2 * $a * $b)
   $Crad = [math]::Acos($cosC)
   $Cdeg = $Crad * 360.0 / (2 * [math]::PI)
   Write-Host "Angle C = $Crad radians ($Cdeg degrees) @ $($referencePoints[1].StationName)"
   Write-Host "Sum = $($Adeg + $Bdeg + $Cdeg)"
}

$fields = @("x","y")

Derive-ABC -Fields $fields -Factor 1.0

$fields = @("Longitude","Latitude")

Derive-ABC -Fields $fields -Factor 1.0

Write-Host "Done"
