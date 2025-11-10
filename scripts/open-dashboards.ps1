#!/usr/bin/env pwsh
# Script to open Prometheus and Grafana dashboards with tunnels

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  OPENING MONITORING DASHBOARDS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[1/3] Opening Prometheus..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '=== PROMETHEUS TUNNEL ACTIVE ===' -ForegroundColor Green; Write-Host 'Keep this window open to access Prometheus' -ForegroundColor Yellow; Write-Host 'URL will open in your browser...' -ForegroundColor Gray; minikube service prometheus -n eci"
Start-Sleep -Seconds 2

Write-Host "[2/3] Opening Grafana..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '=== GRAFANA TUNNEL ACTIVE ===' -ForegroundColor Green; Write-Host 'Keep this window open to access Grafana' -ForegroundColor Yellow; Write-Host 'Login: admin / admin123' -ForegroundColor Cyan; Write-Host 'URL will open in your browser...' -ForegroundColor Gray; minikube service grafana -n eci"
Start-Sleep -Seconds 2

Write-Host "[3/3] Opening Kubernetes Dashboard..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '=== KUBERNETES DASHBOARD ===' -ForegroundColor Green; minikube dashboard"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  DASHBOARDS OPENING!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "What you should see:" -ForegroundColor Yellow
Write-Host "  - 3 PowerShell windows opened (keep them open!)" -ForegroundColor White
Write-Host "  - 3 browser tabs opening automatically`n" -ForegroundColor White

Write-Host "For Grafana:" -ForegroundColor Cyan
Write-Host "  1. Login: admin / admin123" -ForegroundColor White
Write-Host "  2. Click Menu (three lines top-left)" -ForegroundColor White
Write-Host "  3. Click 'Dashboards'" -ForegroundColor White
Write-Host "  4. Click 'ECI Microservices Overview'`n" -ForegroundColor White

Write-Host "For Prometheus:" -ForegroundColor Cyan
Write-Host "  1. Click 'Status' -> 'Targets' to see all services" -ForegroundColor White
Write-Host "  2. All 5 services should show UP" -ForegroundColor White
Write-Host "  3. Click 'Graph' to query metrics`n" -ForegroundColor White

Write-Host "IMPORTANT: Keep the PowerShell tunnel windows open!" -ForegroundColor Yellow
Write-Host "(Closing them will stop dashboard access)`n" -ForegroundColor Red
