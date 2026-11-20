# Desktop & Android Handoff Guide (M10)

Follow these step-by-step instructions once your PC is available.

## 1. Exact Godot Version
- Download **Godot Engine 4.3 (Standard, GDScript)** — NOT the .NET version — from https://godotengine.org/download/archive/4.3-stable/.

## 2. Installation Steps
1. Extract the Godot 4.3 ZIP to a clean folder (e.g., `C:\Tools\Godot_4.3\`).
2. Extract `FrontierCommand_PhaseA_Godot43.zip` to a project folder (e.g., `C:\Projects\frontier_command\`).

## 3. Opening & Importing the Project
1. Launch Godot 4.3.
2. Click **Import**, browse to `C:\Projects\frontier_command\project.godot`, and click **Import & Edit**.
3. Wait for Godot to finish importing assets (`.svg` and `.wav`) and generating `.godot/global_script_class_cache.cfg`.

## 4. First Errors to Inspect
Open the **Output** and **Debugger -> Errors** panels at the bottom:
- Check for any GDScript parse or type-inference errors (copy the exact file name, line number, and error text if any appear).
- Check for any broken `res://` path warnings.
- Open `assets/audio/ambient_loop.wav` in the **Import** dock, set **Loop Mode** to **Forward**, and click **Reimport**.

## 5. Running Automated Tests (CLI)
Open PowerShell or Terminal inside `C:\Projects\frontier_command\` and run:
```bash
# 1. Static check
python3 tools/static_validator.py

# 2. Import class cache (if not already opened in Editor)
godot --headless --path . --import

# 3. Run all 11 Godot headless test suites
godot --headless --path . -s res://tests/test_runner.gd
```
Confirm every suite prints `[PASS]` and ends with `0 failed`.

## 6. Running the Game on Desktop
1. Press **F5** in the Godot Editor (entry scene: `res://scenes/main.tscn`).
2. Click **Play Stage 1** to launch `Savanna Basin`.

## 7. System-by-System Manual Test Checklist
- **Menus:** Open Map Selection (verify all 5 stages appear), Settings (toggle Music/SFX), About & Controls.
- **Population:** Watch your blue capital grow by +1/s up to cap 60; verify neutrals do not grow.
- **Sending & Movement:** Click/tap your blue node, then click a neutral node; test 25%, 50%, and 100% buttons; drag across two friendly nodes to multi-select.
- **Combat & Capture:** Capture a neutral node and verify owner color changes and shake/bump VFX trigger.
- **Special Mechanics:** Launch **Stage 5: Iron Citadel** and verify shields absorb hits, turret fires red beams at passing enemies, speed/slow rings alter movement speed, propaganda boosts growth, and `+50` triggers once on capture.
- **Match Loop:** Pause/Resume, Restart mid-match (verify timer/population/owners reset cleanly), play to Win/Defeat, click Replay and Main Menu.

## 8. Android Export Requirements
1. In Godot Editor: **Editor -> Manage Export Templates -> Download and Install** for Godot 4.3.
2. Install **OpenJDK 17** and **Android Studio** (SDK Platform 34, Build-Tools, Platform-Tools `adb`, Command-line Tools).
3. Configure paths in **Editor -> Editor Settings -> Export -> Android** (Java SDK Path, Android SDK Path, and create a debug keystore via `keytool`).

## 9. APK Build Instructions
1. Go to **Project -> Export -> Add... -> Android**.
2. Set **Package -> Unique Name** (e.g., `com.independent.frontiercommand`).
3. Keep **Architecture** enabled for `arm64-v8a` (OPPO Reno6 Pro uses ARM64).
4. Click **Export Project...**, save as `FrontierCommand_PhaseA_debug.apk`.

## 10. Installing on OPPO Reno6 Pro
1. On your phone: **Settings -> About device -> Version -> tap Build number 7 times** to enable Developer Options.
2. Enable **USB Debugging** under **Additional Settings -> Developer Options**.
3. Connect via USB and run:
```bash
adb devices
adb install -r FrontierCommand_PhaseA_debug.apk
```

## 11. Device Test Checklist (OPPO Reno6 Pro)
- Portrait orientation locks cleanly; HUD buttons clear top notch/camera cutout and bottom gesture bar.
- Single tap selects source cleanly (check for any double-tap firing from mouse emulation).
- Drag multi-select feels responsive with 52 px touch targets.
- Frame rate stays smooth with 100+ troops on screen.
- Audio toggles and Pause/Restart work without freezing.

## 12. How to Report Bugs Back to the AI Agent
Copy and send:
1. Exact Godot **Output/Debugger** error text (file path + line number).
2. Output of `godot --headless --path . -s res://tests/test_runner.gd`.
3. Short description of what you tapped and what happened instead.
