param(
    [string]$ResourceGroup = "rg-travel-agent-demo",
    [string]$AppName,
    [string]$EnvFile = (Join-Path $PSScriptRoot "..\.env")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $EnvFile)) {
    throw "Missing .env file at '$EnvFile'. Create it from .env.example and populate PROJECT_ENDPOINT, AGENT_ID, and AGENT_VERSION."
}

$settings = @{}
Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) { return }
    if ($line -match '^(?<name>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?<value>.*)$') {
        $name = $matches['name'].Trim()
        $value = $matches['value'].Trim().Trim('"').Trim("'")

        if ($name -in @('PROJECT_ENDPOINT', 'AGENT_ID', 'AGENT_VERSION')) {
            $settings[$name] = $value
        }
    }
}

foreach ($required in @('PROJECT_ENDPOINT', 'AGENT_ID', 'AGENT_VERSION')) {
    if (-not $settings.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($settings[$required])) {
        throw "Missing '$required' in '$EnvFile'."
    }
}

if (-not $AppName) {
    $AppName = az webapp list -g $ResourceGroup --query "[0].name" -o tsv
    if (-not $AppName) {
        throw "Could not find an App Service in resource group '$ResourceGroup'. Use -AppName to specify it explicitly."
    }
}

Write-Host "Updating Azure AI Foundry app settings on $AppName..."
$settingsArgs = @(
    "PROJECT_ENDPOINT=$($settings['PROJECT_ENDPOINT'])",
    "AGENT_ID=$($settings['AGENT_ID'])",
    "AGENT_VERSION=$($settings['AGENT_VERSION'])"
)
az webapp config appsettings set -g $ResourceGroup -n $AppName --settings $settingsArgs | Out-Null

Write-Host "Restarting app service..."
az webapp restart -g $ResourceGroup -n $AppName --no-wait | Out-Null

Write-Host "Settings synced successfully."
$filter = "[?name=='PROJECT_ENDPOINT' || name=='AGENT_ID' || name=='AGENT_VERSION']"
Write-Host "Use: az webapp config appsettings list -g $ResourceGroup -n $AppName --query '$filter' -o table"
