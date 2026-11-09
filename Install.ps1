#requires -version 5.1
# Windows first-run setup. Existing Resonance runtime is kept unchanged.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = $PSScriptRoot
$ResonanceDir = Join-Path $ProjectRoot 'Resonance'
$GameDir = Join-Path $ProjectRoot 'Game'
$RuntimeDir = Join-Path $ProjectRoot 'Runtime'
$DownloadsDir = Join-Path $RuntimeDir 'Downloads'
$VenvDir = Join-Path $RuntimeDir 'GameVenv'
$VenvPython = Join-Path $VenvDir 'Scripts\python.exe'
$Stamp = Join-Path $RuntimeDir 'setup_complete.txt'

function Info([string]$Message) { Write-Host ('[Setup] ' + $Message) }
function Require-File([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required file missing: $Path"
    }
}
function Check-Signature([string]$Path, [string]$Publisher) {
    $signature = Get-AuthenticodeSignature -LiteralPath $Path
    if ($signature.Status -ne 'Valid' -or
        $null -eq $signature.SignerCertificate -or
        $signature.SignerCertificate.Subject -notmatch $Publisher) {
        throw "Installer signature could not be verified: $Path ($($signature.Status))"
    }
}
function Download-Installer([string]$Url, [string]$Destination, [string]$Publisher) {
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        Info "Downloading $Url"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Destination
    }
    Check-Signature $Destination $Publisher
}
function Has-VcRedist {
    foreach ($key in @(
        'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
    )) {
        $value = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($null -ne $value -and $value.Installed -eq 1) { return $true }
    }
    return $false
}
function Ensure-VcRedist {
    if (Has-VcRedist) { Info 'VC++ x64 runtime is present.'; return }
    $bundled = Join-Path $ResonanceDir 'qt\bin\vc_redist.x64.exe'
    if (Test-Path -LiteralPath $bundled -PathType Leaf) {
        $installer = $bundled
        Check-Signature $installer 'Microsoft'
    } else {
        $installer = Join-Path $DownloadsDir 'vc_redist.x64.exe'
        Download-Installer 'https://aka.ms/vc14/vc_redist.x64.exe' $installer 'Microsoft'
    }
    Info 'Installing Microsoft VC++ x64 (administrator approval may be needed)...'
    $process = Start-Process -FilePath $installer -ArgumentList '/install /quiet /norestart' -PassThru -Wait -Verb RunAs
    if ($process.ExitCode -eq 3010) {
        throw 'VC++ installed, but Windows must be restarted. Restart and rerun Install.bat.'
    }
    if ($process.ExitCode -notin @(0,1638)) {
        throw "VC++ installer failed with code $($process.ExitCode)."
    }
    Info 'VC++ installation completed.'
}
function Is-Python312([string]$PythonExe) {
    if (-not (Test-Path -LiteralPath $PythonExe -PathType Leaf)) { return $false }
    try {
        & $PythonExe -c 'import sys; sys.exit(0 if sys.version_info[:2] == (3, 12) else 1)' 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch { return $false }
}
function Get-BootstrapPython {
    # Use the Python already available on this PC only to run uv.
    # The game itself receives a separate, project-local Python 3.12 environment.
    foreach ($name in @('python.exe', 'python3.exe')) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -eq $cmd) { continue }
        try {
            & $cmd.Source -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' 2>$null
            if ($LASTEXITCODE -eq 0) { return $cmd.Source }
        } catch {}
    }
    throw 'A working Python 3.8+ command was not found. Install Python from python.org, reopen the terminal, and run Install.bat again.'
}
function Ensure-Uv([string]$BootstrapPython) {
    try {
        & $BootstrapPython -m uv --version 2>$null
        if ($LASTEXITCODE -eq 0) { return }
    } catch {}
    Info 'Installing the small uv environment manager for the current Windows user...'
    & $BootstrapPython -m pip install --user --upgrade uv
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not install uv with the existing Python. Check that "python -m pip --version" works and that internet access is available.'
    }
    & $BootstrapPython -m uv --version
    if ($LASTEXITCODE -ne 0) { throw 'uv installation completed but could not be started with the bootstrap Python.' }
}
function Ensure-ManagedPython312([string]$BootstrapPython) {
    $managedDir = Join-Path $RuntimeDir 'PythonManaged'
    # Keep uv-managed interpreters inside this project and prevent registry
    # discovery/registration. This bypasses the broken python.org MSI bundle
    # registration without deleting or modifying any existing Python install.
    $env:UV_PYTHON_INSTALL_DIR = $managedDir
    $env:UV_PYTHON_NO_REGISTRY = '1'
    $env:UV_PYTHON_INSTALL_REGISTRY = '0'
    $env:UV_PYTHON_PREFERENCE = 'only-managed'

    if (Is-Python312 $VenvPython) {
        Info "Using existing project virtual environment: $VenvPython"
        return $VenvPython
    }

    if (Test-Path -LiteralPath $VenvDir) {
        Info 'Removing only the invalid project virtual environment...'
        Remove-Item -LiteralPath $VenvDir -Recurse -Force
    }

    Info 'Downloading an isolated CPython 3.12.10 runtime into Runtime\\PythonManaged...'
    & $BootstrapPython -m uv venv --python 3.12.10 --seed $VenvDir
    if ($LASTEXITCODE -ne 0) {
        throw 'uv could not create the Python 3.12 environment. Check internet access and the Runtime\\Downloads folder.'
    }
    if (-not (Is-Python312 $VenvPython)) {
        throw "The new virtual environment did not pass the Python 3.12 check: $VenvPython"
    }
    Info "Project Python 3.12 verified: $VenvPython"
    return $VenvPython
}
function Check-Packages {
    if (-not (Test-Path -LiteralPath $VenvPython -PathType Leaf)) { return $false }
    & $VenvPython -c 'import pygame, numpy, scipy, h5py, pyxdf, pylsl' 2>$null
    return ($LASTEXITCODE -eq 0)
}
function Ensure-GameDependencies {
    if (Check-Packages) { Info 'Game and analysis dependencies are already installed.'; return }

    $bootstrapPython = Get-BootstrapPython
    Ensure-Uv $bootstrapPython
    $python = Ensure-ManagedPython312 $bootstrapPython

    $requirements = Join-Path $GameDir 'requirements.txt'
    Require-File $requirements
    $extras = @('pyxdf>=1.17,<2','numpy>=1.26,<3','scipy>=1.11,<2','h5py>=3.10,<4','pylsl>=1.18,<2')
    for ($i = 1; $i -le 3; $i++) {
        Info "Installing Python packages: attempt $i/3 (180-second timeout)..."
        & $python -m pip install --disable-pip-version-check --only-binary=:all: --timeout 180 --retries 10 -r $requirements @extras
        if ($LASTEXITCODE -eq 0) { break }
        if ($i -eq 3) { throw 'pip failed after 3 attempts. Check internet, proxy, or run Install.bat again.' }
        Start-Sleep -Seconds 5
    }
    if (-not (Check-Packages)) { throw 'Python dependency verification failed.' }
    Info 'Python packages verified.'
}

try {
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'Windows x64 is required by this Resonance distribution.' }
    # env.bat sets a private PYTHONHOME; do not let it poison an external Python process.
    foreach ($name in @('PYTHONHOME','PYTHONPATH','PYTHONNOUSERSITE')) {
        Remove-Item -Path ('Env:' + $name) -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $DownloadsDir -Force | Out-Null
    Info 'Checking project files...'
    foreach ($relative in @(
        'Resonance\env.bat', 'Resonance\bin\SPEED.exe',
        'Resonance\params\speed_two_hands.json',
        'Resonance\params\speed_configurator.txt',
        'Resonance\mulines\configured_speed.py', 'Resonance\mulines\contraction_detector.py',
        'Resonance\python\Lib\site-packages\emg_runtime_bootstrap.py',
        'Bridge\config.py', 'Bridge\emg_game_bridge.py', 'Bridge\udp_game_bridge.py', 'Integration\run_game.py',
        'Game\API\gameapi.py',
        'Resonance\data\recording.h5', 'Game\main.py', 'Game\requirements.txt'
    )) { Require-File (Join-Path $ProjectRoot $relative) }
    $profile = Get-Content -LiteralPath (Join-Path $ResonanceDir 'params\speed_two_hands.json') -Encoding UTF8 -Raw | ConvertFrom-Json
    $code = ($profile | Where-Object { $_.name -eq 'code' } | Select-Object -First 1).serialized
    if ($code -notmatch 'emg_runtime_bootstrap\.build') { throw 'Not the expected two-hand SPEED profile.' }
    Ensure-VcRedist
    Ensure-GameDependencies
    [System.IO.File]::WriteAllText($Stamp, 'v12 event-driven ready', [System.Text.Encoding]::ASCII)
    Info 'INSTALLATION OK. Launch Start_All.bat.'
    exit 0
} catch {
    Remove-Item -LiteralPath $Stamp -Force -ErrorAction SilentlyContinue
    Write-Host ('[Setup] ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
