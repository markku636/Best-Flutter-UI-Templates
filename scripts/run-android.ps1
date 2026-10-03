$ErrorActionPreference = 'Stop'
try {
    $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
    $flutterPath = if ($flutterCommand) { $flutterCommand.Source } else { $null }
    if (-not $flutterPath) {
        $searchPaths = @()
        if ($env:FLUTTER_ROOT) { $searchPaths += Join-Path $env:FLUTTER_ROOT 'bin' }
        $searchPaths += ([Environment]::GetEnvironmentVariable('Path', 'User') -split ';')
        $searchPaths += ([Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';')
        foreach ($searchPath in $searchPaths) {
            if (-not $searchPath) { continue }
            $candidate = Join-Path $searchPath.Trim('"') 'flutter.bat'
            if (Test-Path -LiteralPath $candidate) { $flutterPath = $candidate; break }
        }
    }
    if (-not $flutterPath) {
        throw 'Flutter was not found. Add the Flutter bin directory to PATH, or set FLUTTER_ROOT to the SDK directory.'
    }
    $dartPath = Join-Path (Split-Path -Parent $flutterPath) 'dart.bat'
    if (-not (Test-Path -LiteralPath $dartPath)) { throw "Dart was not found next to Flutter: $dartPath" }
    $env:FLUTTER_ROOT = Split-Path -Parent (Split-Path -Parent $flutterPath)
    & $dartPath (Join-Path $PSScriptRoot 'run-mobile.dart') android @args
    exit $LASTEXITCODE
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
