# Biobuzz-18833 Robot Sim

Drive team 18833's robot in a 3D simulation of the 2026-27 FTC field (BIOBUZZ), using the real robot code.
Built on [FTCodeSim](https://github.com/jjophoven/FTCodeSim) and [AdvantageScope](https://github.com/Mechanical-Advantage/AdvantageScope).

What you get:
- the robot's CAD model in AdvantageScope, with moving intake arm, turrets, hood, drive wheels and intake rollers
- a simulated Driver Station (keyboard or Xbox controller)
- field collisions (walls, FLOWERS, HIVE frame) and POLLEN you can intake and shoot
- a **Robot Sim** shortcut on the desktop

This repo has only the simulator. **You need the robot code already** (the team's Biobuzz-18833 project).

## Install (Windows)

Needs: [Android Studio](https://developer.android.com/studio) and
[AdvantageScope 26+](https://github.com/Mechanical-Advantage/AdvantageScope/releases) (open it once after installing).

Open **PowerShell** and run:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/guyka2212/Biobuzz-18833-Sim/main/install.ps1 | iex"
```

It finds your robot project in `AndroidStudioProjects` (or asks for the folder), then:
- copies the simulator into `TeamCode/src/test` (test code - never goes on the robot)
- copies `run-sim.bat` into the project
- adds the simulator libraries to `TeamCode/build.gradle` as `testImplementation` (only if missing)
- creates the **Robot Sim** desktop shortcut

The robot code itself (`TeamCode/src/main`) is not changed. Run the command again any time to update.

## Use

1. Double-click **Robot Sim** (the first start downloads libraries and takes a few minutes).
2. If AdvantageScope is open, close it when asked - the sim reopens it on the **3D FTCodeSim** tab.
3. In the sim Driver Station pick an OpMode (from `TeamCode/.../OpMode`), **Init**, **Start**.
   If AdvantageScope says "Searching": **File > Connect to Simulator**.
4. Close the Driver Station window to stop.

Controls in the Sim Blue OpModes:

| Action | Controller | Keyboard |
|---|---|---|
| Drive / turn | left stick / right stick | W A S D / J L |
| Intake | LT | U |
| Shoot | RT | O |
| Arm down / up | A / B | `;` / `[` |
| Hood | dpad up / down | arrow keys |

## Notes
- The sim robot starts empty (`PRELOAD` in `PollenSim.java`).
- Robot pose, POLLEN counts (`Sim/PollenStored`, `Sim/PollenScored`) and everything else are logged to AdvantageScope and to `TeamCode/sim-logs`.
- Drivetrain physics use FTCodeSim's example values until the team tunes Foresight on the real robot.
