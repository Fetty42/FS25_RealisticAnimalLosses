---
name: fs25-mod-deploy
description: Use when setting up a new FS25 mod for development, creating symlinks to the mods folder, packaging a mod as zip, or configuring modDesc.xml fields like author and descVersion.
---

# FS25 Mod Deployment

## Overview

Handles the full lifecycle of deploying FS25 mods: dev links for live editing, correct zip packaging for distribution, and modDesc.xml standards.

## When to Use

- Setting up a new mod for local development
- Packaging a mod for sharing or publishing
- Creating or updating modDesc.xml
- User mentions "deploy", "package", "zip", "symlink", or "publish" in an FS25 mod context

## Mods Folder by Platform

| Platform    | Path                                                          |
| ----------- | ------------------------------------------------------------- |
| **Windows** | `%USERPROFILE%\Documents\My Games\FarmingSimulator2025\mods\` |
| **macOS**   | `~/Library/Application Support/FarmingSimulator2025/mods/`    |

Game log is in the same parent directory as `mods/`, named `log.txt`.

Detect the platform and use the correct path automatically.

## Dev Setup: Linking

For active development, link the mod folder into the game's mods directory. Changes are picked up immediately without copying.

**macOS:**

```bash
ln -s /absolute/path/to/FS25_ModName "<MODS_FOLDER>/FS25_ModName"
```

**Windows (requires admin or Developer Mode):**

```cmd
mklink /D "%USERPROFILE%\Documents\My Games\FarmingSimulator2025\mods\FS25_ModName" "C:\path\to\FS25_ModName"
```

## Packaging for Distribution

Contents must be at the **root level** of the zip — no nested folder.

**macOS:**

```bash
cd /path/to/FS25_ModName && zip -r ../FS25_ModName.zip . -x "*.DS_Store"
```

**Windows (PowerShell):**

```powershell
Compress-Archive -Path "C:\path\to\FS25_ModName\*" -DestinationPath "C:\path\to\FS25_ModName.zip"
```

| Correct                           | Wrong                                          |
| --------------------------------- | ---------------------------------------------- |
| `zip` root contains `modDesc.xml` | `zip` root contains `FS25_ModName/modDesc.xml` |

**Common mistake**: Zipping the folder itself instead of its contents creates a nested structure. Always zip the _contents_, not the folder.

## modDesc.xml Standards

```xml
<modDesc descVersion="106">
    <author>YOUR NAME HERE</author>
    <!-- ... -->
</modDesc>
```

- **descVersion**: `106` (current as of FS25 patch 1.5)
- **author**: Ask the user if not already known or configured in CLAUDE.md

## Quick Reference

| Task        | macOS/Linux                                           | Windows                                                           |
| ----------- | ----------------------------------------------------- | ----------------------------------------------------------------- |
| Link mod    | `ln -s /path/to/mod "<MODS>/FS25_Name"`               | `mklink /D "<MODS>\FS25_Name" "C:\path\to\mod"`                   |
| Package zip | `cd mod && zip -r ../FS25_Name.zip . -x "*.DS_Store"` | `Compress-Archive -Path "mod\*" -DestinationPath "FS25_Name.zip"` |
| Verify zip  | `unzip -l FS25_Name.zip \| head`                      | `Expand-Archive -Path FS25_Name.zip -ShowList` (or 7zip)          |
| Check log   | `tail -50 "<MODS>/../log.txt"`                        | `Get-Content "<MODS>\..\log.txt" -Tail 50`                        |
| Remove link | `rm "<MODS>/FS25_Name"`                               | `rmdir "<MODS>\FS25_Name"`                                        |
