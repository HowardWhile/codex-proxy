
$Proxy = "http://127.0.0.1:10808"
$NoProxy = "localhost,127.0.0.1,::1"

$ProxyVars = @(
    "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY",
    "http_proxy", "https_proxy", "all_proxy"
)

$NoProxyVars = @("NO_PROXY", "no_proxy")
$Vars = $ProxyVars + $NoProxyVars

function Set-Proxy {
    param(
        [ValidateSet("User", "Process")]
        [string[]]$Scopes = @("User", "Process")
    )

    foreach ($Scope in $Scopes) {
        foreach ($Name in $ProxyVars) {
            [Environment]::SetEnvironmentVariable($Name, $Proxy, $Scope)
        }

        foreach ($Name in $NoProxyVars) {
            [Environment]::SetEnvironmentVariable($Name, $NoProxy, $Scope)
        }
    }

    Write-Host "Proxy enabled: $Proxy" -ForegroundColor Green
}

function Remove-Proxy {
    foreach ($Scope in @("User", "Process")) {
        foreach ($Name in $Vars) {
            [Environment]::SetEnvironmentVariable($Name, $null, $Scope)
        }
    }

    Write-Host "Proxy disabled" -ForegroundColor Yellow
}

function Show-Proxy {
    Write-Host "`nCurrent Proxy Status:" -ForegroundColor Cyan

    foreach ($Name in $Vars) {
        $UserValue = [Environment]::GetEnvironmentVariable($Name, "User")
        $ProcessValue = [Environment]::GetEnvironmentVariable($Name, "Process")

        if (-not $UserValue) { $UserValue = "(Not Set)" }
        if (-not $ProcessValue) { $ProcessValue = "(Not Set)" }

        Write-Host "${Name}:"
        Write-Host "  User:    $UserValue"
        Write-Host "  Process: $ProcessValue"
    }
}

function Start-Codex {
    Set-Proxy -Scopes @("Process")

    Write-Host "`nStarting Codex..." -ForegroundColor Cyan
    codex
}

function Test-Codex {
    Set-Proxy -Scopes @("Process")

    Write-Host "`nTesting Codex..." -ForegroundColor Cyan
    codex exec --skip-git-repo-check "Reply with OK only"
}

while ($true) {
    Write-Host ""
    Write-Host "========== Codex Proxy ==========" -ForegroundColor Cyan
    Write-Host "1. Enable Proxy (Persistent)"
    Write-Host "2. Disable Proxy"
    Write-Host "3. Show Status"
    Write-Host "4. Start Codex TUI"
    Write-Host "5. Test Codex Connection"
    Write-Host "0. Exit"
    Write-Host "================================="

    $Choice = Read-Host "Select"

    switch ($Choice) {
        "1" { Set-Proxy }
        "2" { Remove-Proxy }
        "3" { Show-Proxy }
        "4" { Start-Codex }
        "5" { Test-Codex }
        "0" { exit }
        default {
            Write-Host "Invalid selection" -ForegroundColor Red
        }
    }
}
