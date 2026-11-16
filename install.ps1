# Biobuzz-18833 robot simulator installer
# Adds the FTCodeSim simulator, the robot's 3D model, the launcher and a "Robot Sim" desktop
# shortcut to an EXISTING copy of the robot code. It never changes the robot code itself
# (TeamCode/src/main is not touched).
#
# Run (PowerShell):
#   irm https://raw.githubusercontent.com/guyka2212/Biobuzz-18833-Sim/main/install.ps1 | iex
#
# Optional settings (environment variables, mainly for testing):
#   SIM_PROJECT      robot project folder (skips the question)
#   SIM_SOURCE       use a local copy of this repo instead of downloading it
#   SIM_NO_SHORTCUT  set to 1 to skip the desktop shortcut

$ErrorActionPreference = 'Stop'
$Repo = 'guyka2212/Biobuzz-18833-Sim'
$Branch = 'main'

function Say($text, $color = 'Gray') { Write-Host $text -ForegroundColor $color }

Say ''
Say '=== Biobuzz-18833 Robot Sim installer ===' 'Cyan'
Say ''

# ---------- 1. Find the robot project ----------
$project = $env:SIM_PROJECT
if (-not $project) {
    $root = Join-Path $env:USERPROFILE 'AndroidStudioProjects'
    $candidates = @(Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'TeamCode\build.gradle') })
    if ($candidates.Count -eq 1) {
        $answer = Read-Host "Install into $($candidates[0].FullName) ? (Y/n)"
        if ($answer -eq '' -or $answer -match '^[yY]') { $project = $candidates[0].FullName }
    } elseif ($candidates.Count -gt 1) {
        Say 'Robot projects found:'
        for ($i = 0; $i -lt $candidates.Count; $i++) { Say "  [$($i + 1)] $($candidates[$i].FullName)" }
        $pick = Read-Host 'Which one? (number, or Enter to type a path)'
        if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $candidates.Count) {
            $project = $candidates[[int]$pick - 1].FullName
        }
    }
    if (-not $project) { $project = Read-Host 'Path to your robot project (the folder that contains TeamCode)' }
}
$project = $project.Trim('"', ' ')
if (-not (Test-Path (Join-Path $project 'TeamCode\build.gradle'))) {
    throw "No TeamCode\build.gradle in '$project'. Pick the robot project folder (the one with TeamCode inside)."
}
if (-not (Test-Path (Join-Path $project 'TeamCode\src\main\java\org\firstinspires\ftc\teamcode\OpMode'))) {
    Say "Warning: no TeamCode\src\main\java\org\firstinspires\ftc\teamcode\OpMode folder. The sim lists OpModes from there." 'Yellow'
}
Say "Robot project: $project" 'Green'

# ---------- 2. Get the sim files ----------
$temp = $null
if ($env:SIM_SOURCE) {
    $src = $env:SIM_SOURCE
} else {
    $temp = Join-Path $env:TEMP ("robot-sim-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory $temp | Out-Null
    $zip = Join-Path $temp 'sim.zip'
    Say 'Downloading the simulator (about 30 MB)...'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest "https://github.com/$Repo/archive/refs/heads/$Branch.zip" -OutFile $zip -UseBasicParsing
    Expand-Archive $zip -DestinationPath $temp
    $src = Join-Path $temp ("$(($Repo -split '/')[1])-$Branch")
}
if (-not (Test-Path (Join-Path $src 'files\run-sim.bat'))) { throw "Sim files not found in '$src'." }

# ---------- 3. Copy the simulator (test sources only) and the launcher ----------
$testDir = Join-Path $project 'TeamCode\src\test'
New-Item -ItemType Directory $testDir -Force | Out-Null
Copy-Item (Join-Path $src 'files\TeamCode\src\test\*') $testDir -Recurse -Force
Copy-Item (Join-Path $src 'files\run-sim.bat') $project -Force
Say 'Copied the simulator to TeamCode\src\test and run-sim.bat to the project.' 'Green'

# ---------- 4. Test-only libraries in TeamCode\build.gradle (only if missing) ----------
$gradle = Join-Path $project 'TeamCode\build.gradle'
$text = [IO.File]::ReadAllText($gradle)
if ($text -match 'org\.codeblooded\.ftcodesim') {
    Say 'TeamCode\build.gradle already has the simulator libraries.' 'Green'
} else {
    $block = @'


// ---- Robot simulator (FTCodeSim) - test-only, never goes on the robot. Added by Biobuzz-18833-Sim ----
repositories {
    maven { url 'https://www.jitpack.io' }
    maven { url 'https://repo.dairy.foundation/snapshots' }
}
dependencies {
    testImplementation("org.codeblooded.ftcodesim:ftcodesim:0.2.1-beta")
    testImplementation("junit:junit:4.13.2")
    testImplementation("com.fasterxml.jackson.core:jackson-databind:2.22.3")
}
android {
    testOptions {
        unitTests.all {
            outputs.upToDateWhen { false }
            testLogging { showStandardStreams = true }
        }
    }
}
// ---- end robot simulator ----
'@
    $nl = if ($text -match "`r`n") { "`r`n" } else { "`n" }
    [IO.File]::AppendAllText($gradle, ($block -replace "`r?`n", $nl), (New-Object Text.UTF8Encoding $false))
    Say 'Added the simulator libraries (test-only) to TeamCode\build.gradle.' 'Green'
}

# ---------- 5. Keep sim logs out of git ----------
$gitignore = Join-Path $project '.gitignore'
if ((Test-Path $gitignore) -and -not (Select-String -Path $gitignore -SimpleMatch 'TeamCode/sim-logs/' -Quiet)) {
    Add-Content $gitignore "`r`n# FTCodeSim run logs`r`nTeamCode/sim-logs/" -Encoding ASCII
}

# ---------- 6. Desktop shortcut ----------
$ascopeExe = Join-Path $env:LOCALAPPDATA 'Programs\advantagescope\AdvantageScope.exe'
if ($env:SIM_NO_SHORTCUT -ne '1') {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut((Join-Path $desktop 'Robot Sim.lnk'))
    $lnk.TargetPath = Join-Path $project 'run-sim.bat'
    $lnk.WorkingDirectory = $project
    $lnk.Description = 'Start the FTCodeSim robot simulation'
    if (Test-Path $ascopeExe) { $lnk.IconLocation = "$ascopeExe,0" }
    $lnk.Save()
    Say 'Created the "Robot Sim" shortcut on the desktop.' 'Green'
}

# ---------- 7. Check what the sim needs ----------
Say ''
$ok = $true
if (-not (Test-Path 'C:\Program Files\Android\Android Studio\jbr\bin\java.exe') -and -not $env:JAVA_HOME) {
    Say 'MISSING: Android Studio (the sim uses its built-in Java). Install it from https://developer.android.com/studio' 'Yellow'
    $ok = $false
}
if (-not (Test-Path $ascopeExe)) {
    Say 'MISSING: AdvantageScope 26 or newer. Install it from https://github.com/Mechanical-Advantage/AdvantageScope/releases' 'Yellow'
    $ok = $false
} elseif (-not (Get-ChildItem (Join-Path $env:APPDATA 'AdvantageScope') -Filter 'state-*.json' -ErrorAction SilentlyContinue)) {
    Say 'Open AdvantageScope once and close it again (the sim needs its settings file).' 'Yellow'
    $ok = $false
}

if ($temp) { Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue }

Say ''
if ($ok) { Say 'Done! Double-click "Robot Sim" on the desktop to start.' 'Cyan' }
else { Say 'Installed. Fix the items above, then double-click "Robot Sim" on the desktop.' 'Cyan' }
Say 'In the sim Driver Station: pick an OpMode, Init, Start. First start takes a few minutes (downloads libraries).'
Say ''
