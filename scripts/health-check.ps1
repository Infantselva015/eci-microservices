# Health Check Script for 3 Services Integration
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ECI PLATFORM - HEALTH CHECK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$services = @(
    @{Name="Order Service"; URL="http://localhost:8081/health"; Port=8081},
    @{Name="Payment Service"; URL="http://localhost:8086/health"; Port=8086},
    @{Name="Shipping Service"; URL="http://localhost:8085/health"; Port=8085}
)

$allHealthy = $true

foreach ($service in $services) {
    Write-Host "Checking $($service.Name)..." -NoNewline
    
    try {
        $response = Invoke-RestMethod -Uri $service.URL -TimeoutSec 5
        
        if ($response.status -eq "ok" -or $response.status -eq "healthy") {
            Write-Host " ✅ HEALTHY" -ForegroundColor Green
            Write-Host "  Port: $($service.Port)" -ForegroundColor Gray
        }
        else {
            Write-Host " ⚠ UNHEALTHY" -ForegroundColor Yellow
            $allHealthy = $false
        }
    }
    catch {
        Write-Host " ❌ UNAVAILABLE" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
        $allHealthy = $false
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
if ($allHealthy) {
    Write-Host "  ALL SERVICES HEALTHY ✅" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can access the services at:" -ForegroundColor White
    Write-Host "  Order Service API Docs: http://localhost:8081/docs" -ForegroundColor Cyan
    Write-Host "  Payment Service API Docs: http://localhost:8086/docs" -ForegroundColor Cyan
    Write-Host "  Shipping Service API Docs: http://localhost:8085/docs" -ForegroundColor Cyan
}
else {
    Write-Host "  SOME SERVICES ARE UNHEALTHY ⚠" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if Docker is running: docker ps" -ForegroundColor White
    Write-Host "  2. View service logs: docker-compose logs [service-name]" -ForegroundColor White
    Write-Host "  3. Restart services: docker-compose restart" -ForegroundColor White
}
Write-Host ""
