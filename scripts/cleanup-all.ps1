##############################################
# Cleanup Script - Stop All Services
# Removes all K8s resources and Docker containers
##############################################

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host " CLEANUP: STOPPING ALL SERVICES" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

# Step 1: Delete Kubernetes namespace (this removes all resources)
Write-Host "[STEP 1] Deleting Kubernetes resources..." -ForegroundColor Cyan
kubectl delete namespace eci --ignore-not-found=true

Write-Host "  Waiting for namespace deletion..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Step 2: Stop any running port-forwards
Write-Host "`n[STEP 2] Stopping any running port-forwards..." -ForegroundColor Cyan
Get-Job | Where-Object { $_.Command -like "*port-forward*" } | Stop-Job
Get-Job | Where-Object { $_.Command -like "*port-forward*" } | Remove-Job

# Step 3: Remove Docker images (optional - comment out if you want to keep images)
Write-Host "`n[STEP 3] Removing Docker images..." -ForegroundColor Cyan
docker rmi -f eci-microservices-catalog-service:latest 2>$null
docker rmi -f eci-microservices-inventory-service:latest 2>$null
docker rmi -f eci-microservices-order-service:latest 2>$null
docker rmi -f eci-microservices-payment-service:latest 2>$null
docker rmi -f eci-microservices-shipping-service:latest 2>$null

# Step 4: Clean up Minikube images
Write-Host "`n[STEP 4] Cleaning up Minikube images..." -ForegroundColor Cyan
minikube image rm eci-microservices-catalog-service:latest 2>$null
minikube image rm eci-microservices-inventory-service:latest 2>$null
minikube image rm eci-microservices-order-service:latest 2>$null
minikube image rm eci-microservices-payment-service:latest 2>$null
minikube image rm eci-microservices-shipping-service:latest 2>$null

# Step 5: Verify cleanup
Write-Host "`n[STEP 5] Verifying cleanup..." -ForegroundColor Cyan
Write-Host "`nKubernetes namespaces:" -ForegroundColor Yellow
kubectl get namespaces

Write-Host "`nKubernetes pods (should be none in 'eci' namespace):" -ForegroundColor Yellow
kubectl get pods -n eci 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [SUCCESS] Namespace 'eci' successfully deleted" -ForegroundColor Green
}

# Step 6: Display Docker images
Write-Host "`nDocker images:" -ForegroundColor Yellow
docker images | Select-String "eci-microservices"

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host " CLEANUP COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta

Write-Host "`nAll services have been stopped and removed." -ForegroundColor White
Write-Host "Minikube is still running. To stop Minikube:" -ForegroundColor White
Write-Host "  minikube stop" -ForegroundColor Yellow
Write-Host "`nTo completely delete Minikube cluster:" -ForegroundColor White
Write-Host "  minikube delete" -ForegroundColor Yellow
Write-Host "`n"
