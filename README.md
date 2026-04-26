# PowerShell File Hash Verifier

**Version 1.0.0**

Detect hidden file modifications using cryptographic hash verification. This PowerShell script creates baseline hash snapshots and compares them against current state to identify files that have been modified, deleted, or added.

## Why This Exists

Timestamps can be forged. File sizes can stay identical while content changes. Traditional diff tools often miss what matters most: the actual bytes. This script uses SHA-256 cryptographic hashing to detect modifications that other tools miss.

## Features

- **Generate mode:** Create hash baselines of directories
- **Verify mode:** Detect modifications against baselines
- **Recursive scanning:** Optional subdirectory inclusion
- **Colour-coded output:** Visual status indicators (OK, MISMATCH, MISSING, NEW)
- **Timestamped reports:** Automatic `.txt` file generation
- **No dependencies:** Uses built-in PowerShell cmdlets only

## Requirements

- PowerShell 5.1 or later (Windows 10+)
- Read access to target directories

## Quick Start

### First-Time Setup: Execution Policy

If you see "cannot be loaded because running scripts is disabled," follow these steps:

**Step 1: Set execution policy**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Step 2: Unblock the file (if downloaded from GitHub)**

```powershell
Unblock-File .\hash_verifier.ps1
```

Windows marks downloaded files as "from the internet" and blocks them even with RemoteSigned policy. `Unblock-File` removes this flag.

**Alternative - Bypass for single run:**

```powershell
powershell -ExecutionPolicy Bypass -File .\hash_verifier.ps1 -Path "C:\ImportantFiles" -Mode Generate
```

### ⚠️ Security: Read Before Running

**Before running this or any script from GitHub:**
- Read the source code completely
- Understand what it does
- Verify it matches the stated purpose

Apply the ABC principle: **Assume nothing. Believe nothing. Check everything.**

This script is not digitally signed because transparency (readable source code) is more valuable than blind trust in a signature. You are the final security control.

---

### Generate a Baseline

```powershell
.\hash_verifier.ps1 -Path "C:\ImportantFiles" -Mode Generate -OutputDir "C:\Baselines"
```

Outputs: `HashVerifier_Generate_[timestamp].txt` containing SHA-256 hashes for all files.

### Verify Against Baseline

```powershell
.\hash_verifier.ps1 -Path "C:\ImportantFiles" -Mode Verify -Manifest "C:\Baselines\HashVerifier_Generate_20260424_153045.txt" -OutputDir "C:\Reports"
```

Outputs: `HashVerifier_Verify_[timestamp].txt` showing OK/MISMATCH/MISSING/NEW status for each file.

### Include Subdirectories

```powershell
.\hash_verifier.ps1 -Path "C:\ImportantFiles" -Mode Generate -OutputDir "C:\Baselines" -Recurse
```

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-Path` | Yes | Directory to scan |
| `-Mode` | Yes | `Generate` or `Verify` |
| `-Manifest` | Only for Verify | Path to baseline file |
| `-OutputDir` | No | Where to write reports (default: current directory) |
| `-Recurse` | No | Include subdirectories |

## Output Example

**Generate mode:**
```
[GENERATE MODE] Hashing files in: C:\ImportantFiles
[GENERATE] C:\ImportantFiles\document.docx
[GENERATE] C:\ImportantFiles\spreadsheet.xlsx
[COMPLETE] Manifest written to: C:\Baselines\HashVerifier_Generate_20260424_153045.txt
```

**Verify mode:**
```
[VERIFY MODE] Comparing current state against: C:\Baselines\HashVerifier_Generate_20260424_153045.txt
[OK]       C:\ImportantFiles\document.docx
[MISMATCH] C:\ImportantFiles\spreadsheet.xlsx
           Expected : A1B2C3D4E5F6...
           Found    : FF00AA11BB22...
[MISSING]  C:\ImportantFiles\deleted_file.txt
[NEW]      C:\ImportantFiles\new_addition.pdf

[SUMMARY]
  OK:       12
  MISMATCH: 1
  MISSING:  1
  NEW:      1
```

## Use Cases

- **Configuration management:** Detect unauthorised changes to system files
- **Compliance auditing:** Prove controlled documents haven't been altered
- **Incident response:** Verify investigation machine integrity
- **Change detection:** Monitor network shares for modifications
- **Deployment verification:** Confirm only expected files changed after updates

## What This Detects That Other Tools Miss

- **Timestamp forgery:** Content changed but timestamp reset
- **Size-preserving edits:** Different content, identical file size
- **File replacement:** Different executable, same size

## Performance Notes

Hashing is CPU-intensive:
- Small files (< 1 MB): Nearly instant
- Medium files (10-100 MB): 1-5 seconds each
- Large files (1+ GB): Several seconds to minutes

For thousands of files, run as scheduled task during off-hours.

## Tutorial

Read the full tutorial on DEV Community: [Why Diff Tools Lie: Detecting Hidden File Changes with PowerShell Hash Verification](https://dev.to/shadowstrike/why-diff-tools-lie-detecting-hidden-file-changes-with-powershell-hash-verification-10ak)

## License

MIT License - See LICENSE file for details

## Author

Built by **ShadowStrike** (Strategos) — where we build actual security tools instead of theatre 🎃. 

Part of the Strategos project for APAC forensic and security tooling.
