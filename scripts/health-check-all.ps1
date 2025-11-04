# Health Check Script for All ECI Services

Write-Host "`n══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "    🏥 ECI Platform - Health Check" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$services = @(
    @{Name="Catalog Service"; URL="http://localhost:8001/health"; Port=8001}
    @{Name="Order Service"; URL="http://localhost:8002/health"; Port=8002}
    @{Name="Inventory Service"; URL="http://localhost:8003/health"; Port=8003}
    @{Name="Notification Service"; URL="http://localhost:8004/health"; Port=8004}
    @{Name="Shipping Service"; URL="http://localhost:8085/health"; Port=8085}
    @{Name="Payment Service"; URL="http://localhost:8086/health"; Port=8086}
)

$healthyCount = 0
$unhealthyCount = 0

foreach ($service in $services) {
    Write-Host "Checking $($service.Name)... " -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $service.URL -Method Get -TimeoutSec 5 -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ HEALTHY" -ForegroundColor Green
            $healthyCount++
        } else {
            Write-Host "⚠️  DEGRADED (Status: $($response.StatusCode))" -ForegroundColor Yellow
            $unhealthyCount++
        }
    } catch {
        Write-Host "❌ UNHEALTHY" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
        $unhealthyCount++
    }
}

Write-Host ""
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Healthy:   $healthyCount / $($services.Count)" -ForegroundColor Green
Write-Host "  Unhealthy: $unhealthyCount / $($services.Count)" -ForegroundColor $(if ($unhealthyCount -eq 0) { "Green" } else { "Red" })
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($unhealthyCount -eq 0) {
    Write-Host "🎉 All services are healthy and ready!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Some services are not healthy. Please check the logs." -ForegroundColor Yellow
    exit 1
}
