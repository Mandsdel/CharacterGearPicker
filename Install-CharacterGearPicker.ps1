[CmdletBinding()]
param(
    [string]$AddOnsPath = 'D:\World of Warcraft\_forever_\Interface\AddOns'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    if (-not (Test-Path -LiteralPath $AddOnsPath -PathType Container)) {
        throw "WoW AddOns directory was not found: $AddOnsPath"
    }

    $files = 'CharacterGearPicker.toc', 'Core.lua'
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $file) -PathType Leaf)) {
            throw "Source file was not found: $file"
        }
    }

    $destination = Join-Path $AddOnsPath 'CharacterGearPicker'
    if (-not (Test-Path -LiteralPath $destination -PathType Container)) {
        New-Item -ItemType Directory -Path $destination | Out-Null
    }

    foreach ($file in $files) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $destination $file) -Force
    }

    Write-Host "Installed CharacterGearPicker to $destination"
    Write-Host 'Enable CharacterGearPicker at character select or use /reload if it is already enabled.'
}
catch {
    [Console]::Error.WriteLine("CharacterGearPicker installation failed. $($_.Exception.Message)")
    exit 1
}
