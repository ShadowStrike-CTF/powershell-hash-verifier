# PowerShell File Hash Verifier
# Version: 1.0.0
# Purpose: Generate hash baselines and detect file modifications
# Author: ShadowStrike (Strategos)
# License: MIT

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Generate","Verify")]
    [string]$Mode,
    
    [Parameter(Mandatory=$false)]
    [string]$Manifest = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = ".",
    
    [Parameter(Mandatory=$false)]
    [switch]$Recurse
)

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

function Get-FileHashMap {
    param([string]$DirectoryPath, [bool]$RecurseSubdirs)
    
    $hashMap = @{}
    
    $files = if ($RecurseSubdirs) {
        Get-ChildItem -Path $DirectoryPath -File -Recurse -ErrorAction SilentlyContinue
    } else {
        Get-ChildItem -Path $DirectoryPath -File -ErrorAction SilentlyContinue
    }
    
    foreach ($file in $files) {
        try {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction Stop
            $hashMap[$file.FullName] = $hash.Hash
        } catch {
            Write-Warning "Could not hash file: $($file.FullName)"
        }
    }
    
    return $hashMap
}

if ($Mode -eq "Generate") {
    Write-Host "[GENERATE MODE] Hashing files in: $Path" -ForegroundColor Cyan
    
    $hashMap = Get-FileHashMap -DirectoryPath $Path -RecurseSubdirs $Recurse
    
    $outputFile = Join-Path $OutputDir "HashVerifier_Generate_$timestamp.txt"
    
    $output = @()
    $output += "# Hash Baseline Generated: $(Get-Date)"
    $output += "# Path: $Path"
    $output += "# Recurse: $Recurse"
    $output += "# Total Files: $($hashMap.Count)"
    $output += ""
    
    foreach ($key in ($hashMap.Keys | Sort-Object)) {
        $line = "$($hashMap[$key])  $key"
        $output += $line
        Write-Host "[GENERATE] $key" -ForegroundColor Green
    }
    
    $output | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "`n[COMPLETE] Manifest written to: $outputFile" -ForegroundColor Green
    Write-Host "[INFO] Use this file as -Manifest parameter in Verify mode" -ForegroundColor Yellow
    
} elseif ($Mode -eq "Verify") {
    if (-not $Manifest -or -not (Test-Path $Manifest)) {
        Write-Error "Verify mode requires a valid -Manifest file path"
        exit 1
    }
    
    Write-Host "[VERIFY MODE] Comparing current state against: $Manifest" -ForegroundColor Cyan
    
    # Load baseline hashes
    $baselineMap = @{}
    $manifestLines = Get-Content $Manifest | Where-Object { $_ -notmatch '^#' -and $_.Trim() -ne '' }
    
    foreach ($line in $manifestLines) {
        if ($line -match '^([A-F0-9]{64})\s{2}(.+)$') {
            $baselineMap[$matches[2]] = $matches[1]
        }
    }
    
    Write-Host "[INFO] Baseline contains $($baselineMap.Count) files" -ForegroundColor Yellow
    
    # Get current hashes
    $currentMap = Get-FileHashMap -DirectoryPath $Path -RecurseSubdirs $Recurse
    
    Write-Host "[INFO] Current directory contains $($currentMap.Count) files`n" -ForegroundColor Yellow
    
    $outputFile = Join-Path $OutputDir "HashVerifier_Verify_$timestamp.txt"
    $output = @()
    $output += "# Hash Verification Run: $(Get-Date)"
    $output += "# Baseline: $Manifest"
    $output += "# Path: $Path"
    $output += ""
    
    $okCount = 0
    $mismatchCount = 0
    $missingCount = 0
    $newCount = 0
    
    # Check for matches and mismatches
    foreach ($filePath in ($baselineMap.Keys | Sort-Object)) {
        if ($currentMap.ContainsKey($filePath)) {
            if ($currentMap[$filePath] -eq $baselineMap[$filePath]) {
                Write-Host "[OK]       $filePath" -ForegroundColor Green
                $output += "[OK] $filePath"
                $okCount++
            } else {
                Write-Host "[MISMATCH] $filePath" -ForegroundColor Red
                Write-Host "           Expected : $($baselineMap[$filePath])" -ForegroundColor Gray
                Write-Host "           Found    : $($currentMap[$filePath])" -ForegroundColor Gray
                $output += "[MISMATCH] $filePath"
                $output += "           Expected : $($baselineMap[$filePath])"
                $output += "           Found    : $($currentMap[$filePath])"
                $mismatchCount++
            }
        } else {
            Write-Host "[MISSING]  $filePath" -ForegroundColor Magenta
            $output += "[MISSING] $filePath"
            $missingCount++
        }
    }
    
    # Check for new files
    foreach ($filePath in ($currentMap.Keys | Sort-Object)) {
        if (-not $baselineMap.ContainsKey($filePath)) {
            Write-Host "[NEW]      $filePath" -ForegroundColor Yellow
            $output += "[NEW] $filePath"
            $output += "           Hash: $($currentMap[$filePath])"
            $newCount++
        }
    }
    
    $output += ""
    $output += "# Summary"
    $output += "# OK:       $okCount"
    $output += "# MISMATCH: $mismatchCount"
    $output += "# MISSING:  $missingCount"
    $output += "# NEW:      $newCount"
    
    $output | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "`n[SUMMARY]" -ForegroundColor Cyan
    Write-Host "  OK:       $okCount" -ForegroundColor Green
    Write-Host "  MISMATCH: $mismatchCount" -ForegroundColor Red
    Write-Host "  MISSING:  $missingCount" -ForegroundColor Magenta
    Write-Host "  NEW:      $newCount" -ForegroundColor Yellow
    Write-Host "`n[COMPLETE] Report written to: $outputFile" -ForegroundColor Green
}
