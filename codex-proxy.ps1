
$Proxy = "http://127.0.0.1:10808"
$SettingsPath = Join-Path $env:APPDATA "Code\User\settings.json"

function Update-VSCodeSetting {
    param(
        [string]$Key,
        [string]$Value
    )

    $content = [System.IO.File]::ReadAllText($SettingsPath)
    $escapedKey = [regex]::Escape($Key)
    $pattern = '(?m)^([ \t]*)"' + $escapedKey + '"\s*:\s*[^\r\n]*'

    if ([regex]::IsMatch($content, $pattern)) {
        $content = [regex]::Replace(
            $content, $pattern,
            { param($m) $m.Groups[1].Value + '"' + $Key + '": ' + $Value },
            1
        )
    }
    else {
        $pos = $content.LastIndexOf("}")
        if ($pos -lt 0) {
            throw "Invalid VS Code settings.json"
        }

        $before = $content.Substring(0, $pos)
        $after = $content.Substring($pos)

        # Add separator if needed
        $trimmed = $before.TrimEnd()
        if (-not $trimmed.EndsWith("{") -and
            -not $trimmed.EndsWith(",")) {
            $before = $trimmed + "," + [Environment]::NewLine
        }

        $content = $before + '    "' + $Key + '": ' +
                   $Value + [Environment]::NewLine + $after
    }

    [System.IO.File]::WriteAllText(
        $SettingsPath, $content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Set-Proxy {
    if (-not (Test-Path $SettingsPath)) {
        New-Item -ItemType Directory -Force `
            (Split-Path $SettingsPath) | Out-Null
        Set-Content $SettingsPath "{}" -Encoding UTF8
    }

    Copy-Item $SettingsPath "$SettingsPath.bak" -Force

    Update-VSCodeSetting "http.proxy" "`"$Proxy`""
    Update-VSCodeSetting "http.proxySupport" '"override"'
    Update-VSCodeSetting "http.noProxy" '["localhost", "127.0.0.1", "::1"]'

    Write-Host "VS Code Proxy enabled: $Proxy" -ForegroundColor Green
    Write-Host "Reload VS Code to apply changes."
}

function Remove-Proxy {
    if (-not (Test-Path $SettingsPath)) { return }

    Copy-Item $SettingsPath "$SettingsPath.bak" -Force

    Update-VSCodeSetting "http.proxy" '""'
    Update-VSCodeSetting "http.proxySupport" '"off"'
    Update-VSCodeSetting "http.noProxy" '[]'

    Write-Host "VS Code Proxy disabled" -ForegroundColor Yellow
    Write-Host "Reload VS Code to apply changes."
}

function Show-Proxy {
    Write-Host "`nVS Code Proxy Settings:" -ForegroundColor Cyan

    if (-not (Test-Path $SettingsPath)) {
        Write-Host "Settings file not found"
        return
    }

    Select-String -Path $SettingsPath `
        -Pattern '"http\.(proxy|proxySupport|noProxy)"\s*:'
}

while ($true) {
    Write-Host ""
    Write-Host "========== VS Code Proxy ==========" -ForegroundColor Cyan
    Write-Host "1. Enable Proxy"
    Write-Host "2. Disable Proxy"
    Write-Host "3. Show Status"
    Write-Host "0. Exit"
    Write-Host "==================================="

    switch (Read-Host "Select") {
        "1" { Set-Proxy }
        "2" { Remove-Proxy }
        "3" { Show-Proxy }
        "0" { exit }
        default {
            Write-Host "Invalid selection" -ForegroundColor Red
        }
    }
}
