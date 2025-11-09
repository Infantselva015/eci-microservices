##############################################
# MASTER DEPLOYMENT SCRIPT
# Deploys all 5 services, seeds 300 products, and runs E2E tests
##############################################

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host " ECI PLATFORM - COMPLETE DEPLOYMENT" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

$ErrorActionPreference = "Continue"  # Changed from Stop to Continue
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseDir = Split-Path -Parent $scriptDir
$parentDir = Split-Path -Parent $baseDir  # Go up to Final_Submission folder

# Step 1: Deploy all services
Write-Host "`n[PHASE 1] Deploying all services to Kubernetes..." -ForegroundColor Cyan
Write-Host ""

# Build Docker images
Write-Host "[STEP 1] Building Docker images..." -ForegroundColor Yellow
Write-Host "  (This may take 2-3 minutes...)" -ForegroundColor Gray
Write-Host ""

Write-Host "  Building Catalog Service..." -ForegroundColor Gray
$catalogPath = Join-Path $parentDir "eci-catalog-service"
docker build -t eci-microservices-catalog-service:latest $catalogPath
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Catalog build failed" -ForegroundColor Red; exit 1 }

Write-Host "`n  Building Inventory Service..." -ForegroundColor Gray
$inventoryPath = Join-Path $parentDir "eci-inventory-service"
docker build -t eci-microservices-inventory-service:latest $inventoryPath
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Inventory build failed" -ForegroundColor Red; exit 1 }

Write-Host "`n  Building Order Service..." -ForegroundColor Gray
$orderPath = Join-Path $parentDir "eci-order-service"
docker build -t eci-microservices-order-service:latest $orderPath
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Order build failed" -ForegroundColor Red; exit 1 }

Write-Host "`n  Building Payment Service..." -ForegroundColor Gray
$paymentPath = Join-Path $parentDir "eci-payment-service"
docker build -t eci-microservices-payment-service:latest $paymentPath
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Payment build failed" -ForegroundColor Red; exit 1 }

Write-Host "`n  Building Shipping Service..." -ForegroundColor Gray
$shippingPath = Join-Path $parentDir "eci-shipping-service"
docker build -t eci-microservices-shipping-service:latest $shippingPath
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Shipping build failed" -ForegroundColor Red; exit 1 }

Write-Host "`n[SUCCESS] All images built" -ForegroundColor Green
Write-Host ""

# Load images to Minikube
Write-Host "[STEP 2] Loading images to Minikube..." -ForegroundColor Yellow
minikube image load eci-microservices-catalog-service:latest
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Failed to load catalog image" -ForegroundColor Red; exit 1 }
minikube image load eci-microservices-inventory-service:latest
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Failed to load inventory image" -ForegroundColor Red; exit 1 }
minikube image load eci-microservices-order-service:latest
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Failed to load order image" -ForegroundColor Red; exit 1 }
minikube image load eci-microservices-payment-service:latest
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Failed to load payment image" -ForegroundColor Red; exit 1 }
minikube image load eci-microservices-shipping-service:latest
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Failed to load shipping image" -ForegroundColor Red; exit 1 }
Write-Host "[SUCCESS] All images loaded to Minikube" -ForegroundColor Green
Write-Host ""

# Apply K8s manifests
Write-Host "[STEP 3] Deploying to Kubernetes..." -ForegroundColor Yellow
kubectl apply -f "$baseDir/k8s/deploy-all-services.yaml"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "[SUCCESS] Deployment manifests applied" -ForegroundColor Green

# Wait for pods to be ready
Write-Host "`n[STEP 4] Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod --all -n eci --timeout=120s 2>$null
Write-Host ""

# Wait for services to stabilize after initial restarts
Write-Host "`n[STABILIZATION] Waiting for services to fully stabilize..." -ForegroundColor Yellow
Write-Host "Services may restart 1-2 times while databases initialize." -ForegroundColor White
Write-Host "Waiting 45 seconds..." -ForegroundColor White

for ($i = 45; $i -gt 0; $i--) {
    Write-Host -NoNewline "`r  Time remaining: $i seconds  " -ForegroundColor Cyan
    Start-Sleep -Seconds 1
}
Write-Host "`n"

# Verify all services are running
Write-Host "Verifying all services are running..." -ForegroundColor Cyan
$pods = kubectl get pods -n eci --no-headers
$notReady = $pods | Where-Object { $_ -notmatch "1/1\s+Running" -and $_ -notmatch "mysql|postgres" }

if ($notReady) {
    Write-Host "[WARNING] Some services are not ready yet. Waiting an additional 15 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
}

kubectl get pods -n eci
Write-Host "[SUCCESS] Stabilization complete!" -ForegroundColor Green

# Step 2: Seed 300 products
Write-Host "`n[PHASE 2] Seeding 300 products..." -ForegroundColor Cyan
& "$scriptDir\seed-300-products.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Product seeding failed!" -ForegroundColor Red
    exit 1
}

# Step 3: Seed inventory data
Write-Host "`n[PHASE 3] Seeding inventory data..." -ForegroundColor Cyan
& "$scriptDir\seed-inventory.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Inventory seeding failed!" -ForegroundColor Red
    exit 1
}

# Step 4: Place sample orders
Write-Host "`n[PHASE 4] Placing sample orders..." -ForegroundColor Cyan
Write-Host "Creating orders to demonstrate complete workflow..." -ForegroundColor White
& "$scriptDir\test-place-order.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[WARNING] Order placement had issues, but continuing..." -ForegroundColor Yellow
}

# Step 5: Run E2E tests
Write-Host "`n[PHASE 5] Running E2E tests..." -ForegroundColor Cyan
Write-Host "Tests will verify all services are healthy and responding..." -ForegroundColor White
& "$scriptDir\test-all-services-k8s.ps1"

$testResult = $LASTEXITCODE

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host " DEPLOYMENT PIPELINE COMPLETE" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

if ($testResult -eq 0) {
    Write-Host "[SUCCESS] All phases completed successfully!" -ForegroundColor Green
    Write-Host "`nYou can now:" -ForegroundColor Cyan
    Write-Host "  1. Access services via port-forward" -ForegroundColor White
    Write-Host "  2. Run individual service tests" -ForegroundColor White
    Write-Host "  3. View logs: kubectl logs -n eci -l app=<service-name>" -ForegroundColor White
    Write-Host "`nTo cleanup:" -ForegroundColor Cyan
    Write-Host "  .\scripts\cleanup-all.ps1" -ForegroundColor Yellow
    
    # Launch Kubernetes Dashboard
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Opening Kubernetes Dashboard" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[INFO] Launching Kubernetes Dashboard in your browser..." -ForegroundColor Yellow
    Write-Host "[INFO] Select namespace 'eci' to view all services" -ForegroundColor Yellow
    Write-Host ""
    
    Start-Process powershell -ArgumentList "-Command", "minikube dashboard" -WindowStyle Normal
    
    Write-Host "[SUCCESS] Dashboard launching... Check your browser!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[WARNING] Deployment completed with test failures" -ForegroundColor Yellow
    Write-Host "Check logs above for details" -ForegroundColor White
}

Write-Host "`n"
exit $testResult
