##############################################
# Seed Inventory Data into Inventory Database
##############################################

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host " SEEDING INVENTORY DATA" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Read SQL file and execute directly
Write-Host "Reading SQL file..." -ForegroundColor Cyan
$sqlContent = Get-Content "$scriptDir\seed-inventory.sql" -Raw

# Execute SQL
Write-Host "`nExecuting SQL to insert inventory records..." -ForegroundColor Cyan
Write-Host "This may take 10-20 seconds..." -ForegroundColor Yellow

$podName = kubectl get pod -n eci -l app=inventory-mysql -o jsonpath='{.items[0].metadata.name}'
$sqlContent | kubectl exec -i -n eci $podName -- mysql -u root -prootpassword inventory_db

# Verify
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host " VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta

Write-Host "`nChecking inventory count..." -ForegroundColor Cyan
kubectl exec -n eci deployment/inventory-mysql -- bash -c 'echo "SELECT COUNT(*) as total_inventory_records FROM inventory;" | mysql -u root -prootpassword inventory_db'

Write-Host "`nInventory by warehouse..." -ForegroundColor Cyan
kubectl exec -n eci deployment/inventory-mysql -- bash -c 'echo "SELECT warehouse, COUNT(*) as items, SUM(on_hand) as total_stock, SUM(reserved) as total_reserved FROM inventory GROUP BY warehouse ORDER BY warehouse;" | mysql -u root -prootpassword inventory_db'

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " INVENTORY DATA SEEDED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
