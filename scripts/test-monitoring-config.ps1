##############################################
# TEST MONITORING CONFIGURATION
# Validates Prometheus & Grafana setup
##############################################

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " MONITORING CONFIGURATION TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseDir = Split-Path -Parent $scriptDir
$testsPassed = 0
$testsFailed = 0

# Test 1: Check monitoring YAML exists
Write-Host "[TEST 1] Checking monitoring-stack.yaml exists..." -ForegroundColor Yellow
$monitoringFile = "$baseDir/k8s/monitoring-stack.yaml"
if (Test-Path $monitoringFile) {
    Write-Host "  ✓ PASS: monitoring-stack.yaml found" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: monitoring-stack.yaml not found" -ForegroundColor Red
    $testsFailed++
}

# Test 2: Validate YAML syntax
Write-Host "`n[TEST 2] Validating YAML syntax..." -ForegroundColor Yellow
$kubectlAvailable = Get-Command kubectl -ErrorAction SilentlyContinue
if ($kubectlAvailable) {
    $kubectlTest = kubectl apply -f $monitoringFile --dry-run=client 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ PASS: YAML syntax is valid" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ✗ FAIL: YAML syntax errors" -ForegroundColor Red
        $testsFailed++
    }
} else {
    Write-Host "  ⚠ SKIP: kubectl not available" -ForegroundColor Yellow
}

# Test 3: Check Catalog Service has prom-client
Write-Host "`n[TEST 3] Checking Catalog Service instrumentation..." -ForegroundColor Yellow
$catalogPackage = Get-Content "$baseDir\..\eci-catalog-service\package.json" -Raw | ConvertFrom-Json
if ($catalogPackage.dependencies.'prom-client') {
    Write-Host "  ✓ PASS: prom-client added to Catalog Service" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: prom-client missing from Catalog Service" -ForegroundColor Red
    $testsFailed++
}

# Test 4: Check Catalog Service index.js has metrics
Write-Host "`n[TEST 4] Checking Catalog Service metrics endpoint..." -ForegroundColor Yellow
$catalogIndex = Get-Content "$baseDir\..\eci-catalog-service\index.js" -Raw
if ($catalogIndex -match "promClient" -and $catalogIndex -match "/metrics") {
    Write-Host "  ✓ PASS: Metrics endpoint configured in Catalog Service" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: Metrics endpoint missing in Catalog Service" -ForegroundColor Red
    $testsFailed++
}

# Test 5: Check Inventory Service has prom-client
Write-Host "`n[TEST 5] Checking Inventory Service instrumentation..." -ForegroundColor Yellow
$inventoryPackage = Get-Content "$baseDir\..\eci-inventory-service\package.json" -Raw | ConvertFrom-Json
if ($inventoryPackage.dependencies.'prom-client') {
    Write-Host "  ✓ PASS: prom-client added to Inventory Service" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: prom-client missing from Inventory Service" -ForegroundColor Red
    $testsFailed++
}

# Test 6: Check Order Service has prometheus-fastapi-instrumentator
Write-Host "`n[TEST 6] Checking Order Service instrumentation..." -ForegroundColor Yellow
$orderReqs = Get-Content "$baseDir\..\eci-order-service\requirements.txt" -Raw
if ($orderReqs -match "prometheus-fastapi-instrumentator") {
    Write-Host "  ✓ PASS: prometheus-fastapi-instrumentator added to Order Service" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: prometheus-fastapi-instrumentator missing from Order Service" -ForegroundColor Red
    $testsFailed++
}

# Test 7: Check Payment Service has prometheus-fastapi-instrumentator
Write-Host "`n[TEST 7] Checking Payment Service instrumentation..." -ForegroundColor Yellow
$paymentReqs = Get-Content "$baseDir\..\eci-payment-service\requirements.txt" -Raw
if ($paymentReqs -match "prometheus-fastapi-instrumentator") {
    Write-Host "  ✓ PASS: prometheus-fastapi-instrumentator added to Payment Service" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: prometheus-fastapi-instrumentator missing from Payment Service" -ForegroundColor Red
    $testsFailed++
}

# Test 8: Check Shipping Service has prometheus-fastapi-instrumentator
Write-Host "`n[TEST 8] Checking Shipping Service instrumentation..." -ForegroundColor Yellow
$shippingReqs = Get-Content "$baseDir\..\eci-shipping-service\requirements.txt" -Raw
if ($shippingReqs -match "prometheus-fastapi-instrumentator") {
    Write-Host "  ✓ PASS: prometheus-fastapi-instrumentator added to Shipping Service" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: prometheus-fastapi-instrumentator missing from Shipping Service" -ForegroundColor Red
    $testsFailed++
}

# Test 9: Check deploy-complete.ps1 includes monitoring
Write-Host "`n[TEST 9] Checking deploy-complete.ps1 integration..." -ForegroundColor Yellow
$deployScript = Get-Content "$scriptDir\deploy-complete.ps1" -Raw
if ($deployScript -match "monitoring-stack.yaml" -and $deployScript -match "PHASE 6") {
    Write-Host "  ✓ PASS: Monitoring deployment integrated in deploy-complete.ps1" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: Monitoring not integrated in deploy-complete.ps1" -ForegroundColor Red
    $testsFailed++
}

# Test 10: Check deploy-monitoring.ps1 exists
Write-Host "`n[TEST 10] Checking deploy-monitoring.ps1 script..." -ForegroundColor Yellow
if (Test-Path "$scriptDir\deploy-monitoring.ps1") {
    Write-Host "  ✓ PASS: deploy-monitoring.ps1 script exists" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: deploy-monitoring.ps1 script missing" -ForegroundColor Red
    $testsFailed++
}

# Test 11: Check README.md has monitoring documentation
Write-Host "`n[TEST 11] Checking README.md documentation..." -ForegroundColor Yellow
$readme = Get-Content "$baseDir\README.md" -Raw
if ($readme -match "Prometheus" -and $readme -match "Grafana" -and $readme -match "30900" -and $readme -match "30300") {
    Write-Host "  ✓ PASS: Monitoring documented in README.md" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: Monitoring documentation incomplete in README.md" -ForegroundColor Red
    $testsFailed++
}

# Test 12: Check MONITORING.md exists
Write-Host "`n[TEST 12] Checking MONITORING.md guide..." -ForegroundColor Yellow
if (Test-Path "$baseDir\MONITORING.md") {
    Write-Host "  ✓ PASS: MONITORING.md guide exists" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: MONITORING.md guide missing" -ForegroundColor Red
    $testsFailed++
}

# Test 13: Check monitoring-stack.yaml has Prometheus deployment
Write-Host "`n[TEST 13] Checking Prometheus configuration..." -ForegroundColor Yellow
$monitoringYaml = Get-Content $monitoringFile -Raw
if ($monitoringYaml -match "prom/prometheus" -and $monitoringYaml -match "nodePort: 30900") {
    Write-Host "  ✓ PASS: Prometheus configured correctly" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: Prometheus configuration incomplete" -ForegroundColor Red
    $testsFailed++
}

# Test 14: Check monitoring-stack.yaml has Grafana deployment
Write-Host "`n[TEST 14] Checking Grafana configuration..." -ForegroundColor Yellow
if ($monitoringYaml -match "grafana/grafana" -and $monitoringYaml -match "nodePort: 30300") {
    Write-Host "  ✓ PASS: Grafana configured correctly" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: Grafana configuration incomplete" -ForegroundColor Red
    $testsFailed++
}

# Test 15: Check Prometheus scrape configs for all services
Write-Host "`n[TEST 15] Checking Prometheus scrape configurations..." -ForegroundColor Yellow
$servicesFound = 0
if ($monitoringYaml -match "catalog-service:8080") { $servicesFound++ }
if ($monitoringYaml -match "inventory-service:8081") { $servicesFound++ }
if ($monitoringYaml -match "order-service:8000") { $servicesFound++ }
if ($monitoringYaml -match "payment-service:8006") { $servicesFound++ }
if ($monitoringYaml -match "shipping-service:8005") { $servicesFound++ }

if ($servicesFound -eq 5) {
    Write-Host "  ✓ PASS: All 5 services configured in Prometheus scrape targets" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  ✗ FAIL: Only $servicesFound/5 services configured in Prometheus" -ForegroundColor Red
    $testsFailed++
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " TEST RESULTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$totalTests = $testsPassed + $testsFailed
$passRateValue = ($testsPassed / $totalTests) * 100
$passRate = [math]::Round($passRateValue, 2)

$percentSign = "%"
$passedMessage = "Tests Passed: " + $testsPassed + " / " + $totalTests + " (" + $passRate + $percentSign + ")"
Write-Host $passedMessage -ForegroundColor $(if ($testsPassed -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host "Tests Failed: $testsFailed / $totalTests" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -eq 0) {
    Write-Host "`n✅ ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "`nMonitoring implementation is ready for deployment!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Start minikube: minikube start" -ForegroundColor White
    Write-Host "  2. Run deployment: .\deploy-complete.ps1" -ForegroundColor White
    Write-Host "  3. Access Prometheus: http://localhost:30900" -ForegroundColor White
    Write-Host "  4. Access Grafana: http://localhost:30300 (admin/admin123)" -ForegroundColor White
    exit 0
} else {
    Write-Host "`n⚠️ SOME TESTS FAILED" -ForegroundColor Yellow
    Write-Host "Please review the failures above and fix them." -ForegroundColor White
    exit 1
}
