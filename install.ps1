# Install or update Neovim and this config on Windows. Safe to re-run: each step
# installs what is missing and updates what is already there.
#
#   irm http://192.168.1.91:3001/AnimalRacer3/nvim/raw/branch/main/install.ps1 | iex
#
# Steps:
#   1. Neovim and the tools LazyVim needs, via winget
#   2. This config into %LOCALAPPDATA%\nvim (clone, or fast-forward pull if present)
#   3. The Open WebUI API key, saved outside the repo
#   4. Plugins, pinned to lazy-lock.json
#
# Overrides: $env:NVIM_CONFIG_REPO, $env:NVIM_CONFIG_BRANCH, $env:OPENWEBUI_API_KEY.
$ErrorActionPreference = "Stop"

$Repo = if ($env:NVIM_CONFIG_REPO) { $env:NVIM_CONFIG_REPO } else { "http://192.168.1.91:3001/AnimalRacer3/nvim.git" }
$Branch = if ($env:NVIM_CONFIG_BRANCH) { $env:NVIM_CONFIG_BRANCH } else { "main" }
$ConfigDir = Join-Path $env:LOCALAPPDATA "nvim"
$DataDir = Join-Path $env:LOCALAPPDATA "nvim-data"

function Info($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Warning $msg }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw "winget is required. Install 'App Installer' from the Microsoft Store, then re-run."
}

# Neovim, plus git, ripgrep, fd, and zig as the C compiler nvim-treesitter builds parsers with.
$packages = @("Neovim.Neovim", "Git.Git", "BurntSushi.ripgrep.MSVC", "sharkdp.fd", "zig.zig")
foreach ($id in $packages) {
  winget list --id $id --exact --accept-source-agreements *> $null
  if ($LASTEXITCODE -eq 0) {
    Info "Updating $id"
    winget upgrade --id $id --exact --silent --accept-source-agreements --accept-package-agreements
  } else {
    Info "Installing $id"
    winget install --id $id --exact --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { Warn "winget could not install $id (exit $LASTEXITCODE)" }
  }
}

# Pick up PATH entries the installers just added.
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
foreach ($cmd in @("git", "nvim")) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "'$cmd' is not on PATH yet. Open a new terminal and re-run this script."
  }
}

if (Test-Path (Join-Path $ConfigDir ".git")) {
  Info "Updating config in $ConfigDir"
  git -C $ConfigDir pull --ff-only
  if ($LASTEXITCODE -ne 0) { Warn "could not fast-forward $ConfigDir (local changes?); left as is" }
} else {
  if (Test-Path $ConfigDir) {
    $backup = "$ConfigDir.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Info "Moving existing $ConfigDir to $backup"
    Move-Item $ConfigDir $backup
  }
  Info "Cloning $Repo into $ConfigDir"
  git clone --branch $Branch $Repo $ConfigDir
  if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
}

$keyFile = Join-Path $DataDir "openwebui_api_key"
$key = $env:OPENWEBUI_API_KEY
if (-not $key -and -not (Test-Path $keyFile)) {
  $secure = Read-Host "Open WebUI API key (Settings > Account > API Keys; blank to skip)" -AsSecureString
  $key = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
}
if ($key) {
  New-Item -ItemType Directory -Force $DataDir | Out-Null
  [IO.File]::WriteAllText($keyFile, $key)
  Info "Saved API key to $keyFile"
}

Info "Installing plugins (pinned by lazy-lock.json)"
nvim --headless "+Lazy! restore" "+Lazy! clean" +qa

Info "Done. Run 'nvim'; run this script again any time to update."
