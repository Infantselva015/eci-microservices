##############################################
# DEPLOY MONITORING STACK
# Deploys Prometheus & Grafana to existing ECI namespace
##############################################

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " DEPLOYING MONITORING STACK" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseDir = Split-Path -Parent $scriptDir

# Check if namespace exists
Write-Host "[CHECK] Verifying 'eci' namespace exists..." -ForegroundColor Yellow
$namespace = kubectl get namespace eci 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Namespace 'eci' not found. Please deploy services first." -ForegroundColor Red
    Write-Host "Run: .\deploy-complete.ps1" -ForegroundColor White
    exit 1
}

Write-Host "[SUCCESS] Namespace 'eci' found" -ForegroundColor Green

# Deploy monitoring stack
Write-Host "`n[STEP 1] Deploying Prometheus & Grafana..." -ForegroundColor Yellow
kubectl apply -f "$baseDir/k8s/monitoring-stack.yaml"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Monitoring deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "[SUCCESS] Monitoring manifests applied" -ForegroundColor Green

# Wait for pods
Write-Host "`n[STEP 2] Waiting for monitoring pods to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

kubectl wait --for=condition=ready pod -l app=prometheus -n eci --timeout=60s 2>$null
kubectl wait --for=condition=ready pod -l app=grafana -n eci --timeout=60s 2>$null

Write-Host "[SUCCESS] Monitoring stack is ready!" -ForegroundColor Green

# Display status
Write-Host "`n[STEP 3] Monitoring Stack Status:" -ForegroundColor Yellow
kubectl get pods -n eci -l app=prometheus -o wide
kubectl get pods -n eci -l app=grafana -o wide
kubectl get svc -n eci -l app=prometheus
kubectl get svc -n eci -l app=grafana

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " MONITORING STACK DEPLOYED" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[SUCCESS] Monitoring is now active!" -ForegroundColor Green
Write-Host "`nAccess URLs:" -ForegroundColor Cyan
Write-Host "  Prometheus: http://localhost:30900" -ForegroundColor White
Write-Host "    - Target status: http://localhost:30900/targets" -ForegroundColor Gray
Write-Host "    - Metrics: http://localhost:30900/graph" -ForegroundColor Gray
Write-Host "`n  Grafana: http://localhost:30300" -ForegroundColor White
Write-Host "    - Username: admin" -ForegroundColor Gray
Write-Host "    - Password: admin123" -ForegroundColor Gray
Write-Host "    - Dashboards: ECI Microservices Overview" -ForegroundColor Gray

Write-Host "`nVerify Metrics Endpoints:" -ForegroundColor Cyan
Write-Host "  Catalog:   http://localhost:30090/metrics" -ForegroundColor White
Write-Host "  Inventory: http://localhost:30091/metrics" -ForegroundColor White
Write-Host "  Order:     http://localhost:30082/metrics" -ForegroundColor White
Write-Host "  Payment:   http://localhost:30086/metrics" -ForegroundColor White
Write-Host "  Shipping:  http://localhost:30085/metrics" -ForegroundColor White

Write-Host "`nSample Prometheus Queries:" -ForegroundColor Cyan
Write-Host "  - up{job=~\".*-service\"}  (Service health)" -ForegroundColor Gray
Write-Host "  - rate(http_requests_total[5m])  (Request rate)" -ForegroundColor Gray
Write-Host "  - http_request_duration_seconds  (Response times)" -ForegroundColor Gray

Write-Host "`nTo remove monitoring:" -ForegroundColor Cyan
Write-Host "  kubectl delete -f k8s/monitoring-stack.yaml" -ForegroundColor Yellow

Write-Host "`n"
exit 0
