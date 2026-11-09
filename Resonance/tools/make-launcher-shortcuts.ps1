<#
.SYNOPSIS
    Gives every launcher of a Resonance distribution an icon in Explorer.

.DESCRIPTION
    A .bat file cannot carry an icon: Explorer draws the batch-file glyph for the extension, and
    nothing inside the file changes that. A shortcut can. This writes <Root>\launch\<name>.lnk for
    every launcher in the root that starts a Resonance program -- the file names an .exe or a
    --builtIn -- and has no "rem launchbar: hide" line (the Configurator's icon strip is a
    separate, operator-edited list, <Root>\launchbar.txt), with

        target      <Root>\<name>.bat
        start in    <Root>
        icon        the executable the launcher starts (its IDI_ICON1, resource index 0), or for
                    the three tools inside quickStimulus.exe the icon group resonance_icon()
                    embeds for each: configurator -101, recorder -102, messageSender -103
        run         minimised, so the launcher's console is a taskbar blink rather than a flash

    Shortcuts hold absolute paths. Run this again after moving or copying the distribution; a
    copy of the script is installed as <Root>\tools\make-launcher-shortcuts.ps1 for that.
    deploy-qt6.ps1 runs it as its last step. Shortcuts whose launcher is gone are removed.

.PARAMETER Root
    The distribution root, the directory holding bin\ and the .bat launchers. Defaults to the
    parent of this script's directory when that is a distribution (the tools\ copy), else R:\dist.

.PARAMETER Folder
    The subdirectory of Root that receives the shortcuts. Default: launch.
#>
[CmdletBinding()]
param(
    [string]$Root = '',
    [string]$Folder = 'launch'
)

$ErrorActionPreference = 'Stop'

if ($Root -eq '') {
    $candidate = Split-Path -Parent $PSScriptRoot
    if (Test-Path -LiteralPath (Join-Path $candidate 'bin\quickStimulus.exe') -PathType Leaf) {
        $Root = $candidate
    } else {
        $Root = 'R:\dist'
    }
}
$rootPath = [IO.Path]::GetFullPath($Root)
if (-not (Test-Path -LiteralPath (Join-Path $rootPath 'bin') -PathType Container)) {
    throw "Not a distribution root (no bin\ inside): $rootPath"
}
$launchPath = Join-Path $rootPath $Folder
New-Item -ItemType Directory -Force -Path $launchPath | Out-Null

# The numeric icon groups quickStimulus/CMakeLists.txt gives its built-in tools:
#     resonance_icon(quickStimulus resonance 101=configurator 102=recorder 103=message-sender)
$builtInIcons = @{ configurator = 101; recorder = 102; messagesender = 103; generator = 103 }

function Find-Executable([string]$name) {
    $direct = Join-Path $rootPath "bin\$name.exe"
    if (Test-Path -LiteralPath $direct -PathType Leaf) { return $direct }
    # An executable may sit one level down in a directory of its own (a driver that needs its own
    # generation of a vendor DLL is installed that way).
    foreach ($sub in Get-ChildItem -LiteralPath (Join-Path $rootPath 'bin') -Directory) {
        $nested = Join-Path $sub.FullName "$name.exe"
        if (Test-Path -LiteralPath $nested -PathType Leaf) { return $nested }
    }
    return $null
}

$shell = New-Object -ComObject WScript.Shell
$written = New-Object System.Collections.Generic.List[string]
$withoutIcon = New-Object System.Collections.Generic.List[string]

foreach ($launcher in Get-ChildItem -LiteralPath $rootPath -Filter '*.bat' -File | Sort-Object Name) {
    $text = Get-Content -LiteralPath $launcher.FullName -Raw
    if ($text -match '(?im)^\s*rem\s+launchbar\s*:\s*hide\b') { continue }

    $icon = $null
    if ($text -match '(?i)--builtIn\s+([A-Za-z0-9_]+)') {
        $exe = Find-Executable 'quickStimulus'
        $id = $builtInIcons[$matches[1].ToLowerInvariant()]
        if ($exe) {
            if ($id) { $icon = "$exe,-$id" } else { $icon = "$exe,0" }
        }
    } elseif ($text -match '(?i)([A-Za-z0-9_.\-]+)\.exe\b') {
        $exe = Find-Executable $matches[1]
        if ($exe) { $icon = "$exe,0" }
    } else {
        continue
    }

    $name = $launcher.BaseName
    $shortcut = $shell.CreateShortcut((Join-Path $launchPath "$name.lnk"))
    $shortcut.TargetPath = $launcher.FullName
    $shortcut.WorkingDirectory = $rootPath
    $shortcut.Description = "Resonance: $name.bat"
    $shortcut.WindowStyle = 7
    if ($icon) { $shortcut.IconLocation = $icon } else { $withoutIcon.Add($name) }
    $shortcut.Save()
    $written.Add("$name.lnk")
}

# A launcher renamed or removed leaves no shortcut behind.
Get-ChildItem -LiteralPath $launchPath -Filter '*.lnk' -File |
    Where-Object { -not $written.Contains($_.Name) } |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

Write-Host "$($written.Count) launcher shortcuts in $launchPath"
if ($withoutIcon.Count -gt 0) {
    Write-Warning ("No executable found for: " + ($withoutIcon -join ', ') +
                   " -- those shortcuts wear the default icon")
}
