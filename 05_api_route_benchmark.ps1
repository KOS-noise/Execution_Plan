param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$Path = "/api/product/getAll?page=1&size=9&minPrice=10000&maxPrice=200000&categories=sneakers",
    [int]$Warmup = 10,
    [int]$Runs = 50
)

$ErrorActionPreference = "Stop"

function Measure-LatencyStats {
    param(
        [string]$Url,
        [int]$WarmupCount,
        [int]$RunCount
    )

    for ($i = 1; $i -le $WarmupCount; $i++) {
        Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing | Out-Null
    }

    $samples = @()
    for ($i = 1; $i -le $RunCount; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing | Out-Null
        $sw.Stop()
        $samples += $sw.Elapsed.TotalMilliseconds
    }

    $sorted = $samples | Sort-Object
    $avg = ($samples | Measure-Object -Average).Average
    $median = $sorted[[int][Math]::Floor($RunCount / 2)]
    $p95Index = [Math]::Min([int][Math]::Ceiling($RunCount * 0.95) - 1, $RunCount - 1)
    $p95 = $sorted[$p95Index]

    return [PSCustomObject]@{
        AverageMs = [Math]::Round($avg, 2)
        MedianMs  = [Math]::Round($median, 2)
        P95Ms     = [Math]::Round($p95, 2)
    }
}

$url = "{0}{1}" -f $BaseUrl, $Path
Write-Host ""
Write-Host "[1/2] Legacy route measurement (before behavior)"
Write-Host "Run server with: -Dapp.product.search.filter-aware-routing=false"
Write-Host ("Target URL: {0}" -f $url)
$legacy = Measure-LatencyStats -Url $url -WarmupCount $Warmup -RunCount $Runs

Write-Host ""
Write-Host "[2/2] Improved route measurement (after behavior)"
Write-Host "Restart server with: -Dapp.product.search.filter-aware-routing=true"
Read-Host "Restarted? Press Enter to continue"
$improved = Measure-LatencyStats -Url $url -WarmupCount $Warmup -RunCount $Runs

$improvement = if ($legacy.AverageMs -gt 0) {
    [Math]::Round((($legacy.AverageMs - $improved.AverageMs) / $legacy.AverageMs) * 100, 2)
} else {
    0
}

Write-Host ""
Write-Host "===== Benchmark Result ====="
Write-Host ("Before  - Avg: {0} ms, Median: {1} ms, P95: {2} ms" -f $legacy.AverageMs, $legacy.MedianMs, $legacy.P95Ms)
Write-Host ("After   - Avg: {0} ms, Median: {1} ms, P95: {2} ms" -f $improved.AverageMs, $improved.MedianMs, $improved.P95Ms)
Write-Host ("Improvement (Avg): {0} %" -f $improvement)
