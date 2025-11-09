##############################################
# Seed 300 Products into Catalog Database
##############################################

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host " SEEDING 300 PRODUCTS" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Read SQL file and execute directly
Write-Host "Reading SQL file..." -ForegroundColor Cyan
$sqlContent = Get-Content "$scriptDir\seed-300-products.sql" -Raw

# Execute SQL
Write-Host "`nExecuting SQL to insert 300 products..." -ForegroundColor Cyan
Write-Host "This may take 30-60 seconds..." -ForegroundColor Yellow

$podName = kubectl get pod -n eci -l app=catalog-mysql -o jsonpath='{.items[0].metadata.name}'
$sqlContent | kubectl exec -i -n eci $podName -- mysql -u root -prootpassword catalog_db

# Verify
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host " VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

Write-Host "`nChecking product count..." -ForegroundColor Cyan
kubectl exec -n eci deployment/catalog-mysql -- bash -c 'echo "SELECT COUNT(*) as total_products FROM products;" | mysql -u root -prootpassword catalog_db'

Write-Host "`nProducts by category..." -ForegroundColor Cyan
kubectl exec -n eci deployment/catalog-mysql -- bash -c 'echo "SELECT category, COUNT(*) as count FROM products GROUP BY category ORDER BY category;" | mysql -u root -prootpassword catalog_db'

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " 300 PRODUCTS SEEDED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
