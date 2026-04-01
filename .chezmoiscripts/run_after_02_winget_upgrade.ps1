if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "Error: winget is not installed."
    exit 1
}

Write-Host "Upgrading all winget packages..."
winget upgrade -r --accept-package-agreements --accept-source-agreements
Write-Host "Winget upgrade complete."
