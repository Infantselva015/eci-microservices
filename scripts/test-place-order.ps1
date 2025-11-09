# Simple Order Placement Test
# Demonstrates placing an order through the ECI platform

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  ECI Platform - Place Order Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Service URLs
$CATALOG_URL = "http://localhost:9090"
$INVENTORY_URL = "http://localhost:9091"
$ORDER_URL = "http://localhost:9082"
$PAYMENT_URL = "http://localhost:9086"

Write-Host "[INFO] Starting port-forwards..." -ForegroundColor Yellow
$portForwards = @()
$portForwards += Start-Process powershell -ArgumentList "-Command", "kubectl port-forward -n eci svc/catalog-service 9090:8080" -WindowStyle Hidden -PassThru
$portForwards += Start-Process powershell -ArgumentList "-Command", "kubectl port-forward -n eci svc/inventory-service 9091:8081" -WindowStyle Hidden -PassThru
$portForwards += Start-Process powershell -ArgumentList "-Command", "kubectl port-forward -n eci svc/order-service 9082:8000" -WindowStyle Hidden -PassThru
$portForwards += Start-Process powershell -ArgumentList "-Command", "kubectl port-forward -n eci svc/payment-service 9086:8006" -WindowStyle Hidden -PassThru

Start-Sleep -Seconds 5
Write-Host ""

try {
    # Step 1: Get a product
    Write-Host "[STEP 1] Browsing products..." -ForegroundColor Yellow
    $products = Invoke-RestMethod -Uri "$CATALOG_URL/v1/products?limit=1" -Method Get
    $product = $products[0]
    Write-Host "[SUCCESS] Found: $($product.name) - $($product.sku) - `$$($product.price)" -ForegroundColor Green
    Write-Host ""

    # Step 2: Check inventory
    Write-Host "[STEP 2] Checking inventory for $($product.sku)..." -ForegroundColor Yellow
    $inventory = Invoke-RestMethod -Uri "$INVENTORY_URL/v1/inventory/$($product.sku)" -Method Get
    $totalStock = ($inventory | Measure-Object -Property on_hand -Sum).Sum
    Write-Host "[SUCCESS] Available stock: $totalStock units in $($inventory.Count) warehouse(s)" -ForegroundColor Green
    Write-Host ""

    # Step 3: Create order
    Write-Host "[STEP 3] Creating order..." -ForegroundColor Yellow
    $orderQuantity = 2
    $unitPrice = [decimal]$product.price
    $shipping = 99.99
    $total = ($unitPrice * $orderQuantity) + $shipping
    
    # Convert UUID to integer for order service
    $productIdInt = [Math]::Abs(($product.product_id.GetHashCode())) % 999999 + 1
    
    $orderBody = @{
        customer_id = 1
        items = @(
            @{
                product_id = $productIdInt
                sku = $product.sku
                name = $product.name
                quantity = $orderQuantity
                unit_price = $unitPrice
            }
        )
        shipping = $shipping
    } | ConvertTo-Json -Depth 4

    $headers = @{
        "Content-Type" = "application/json"
        "Idempotency-Key" = "order-$(Get-Date -Format 'yyyyMMddHHmmss')"
    }

    $order = Invoke-RestMethod -Uri "$ORDER_URL/v1/orders" -Method Post -Body $orderBody -Headers $headers
    Write-Host "[SUCCESS] Order created!" -ForegroundColor Green
    Write-Host "  Order ID: $($order.order_id)" -ForegroundColor White
    Write-Host "  Status: $($order.status)" -ForegroundColor White
    Write-Host "  Total Amount: `$$([math]::Round($order.total, 2))" -ForegroundColor White
    Write-Host ""

    # Step 4: Process payment
    Write-Host "[STEP 4] Processing payment..." -ForegroundColor Yellow
    $paymentBody = @{
        order_id = [int]$order.order_id
        user_id = 1
        amount = [math]::Round($total, 2)
        currency = "USD"
        payment_method = "CREDIT_CARD"
        reference = "payment-$(Get-Date -Format 'yyyyMMddHHmmss')"
    } | ConvertTo-Json -Depth 4

    $paymentHeaders = @{
        "Content-Type" = "application/json"
        "Idempotency-Key" = "payment-$(Get-Date -Format 'yyyyMMddHHmmss')"
    }

    $payment = Invoke-RestMethod -Uri "$PAYMENT_URL/v1/payments" -Method Post -Body $paymentBody -Headers $paymentHeaders
    Write-Host "[SUCCESS] Payment processed!" -ForegroundColor Green
    Write-Host "  Payment ID: $($payment.payment_id)" -ForegroundColor White
    Write-Host "  Status: $($payment.status)" -ForegroundColor White
    Write-Host "  Amount: `$$($payment.amount) $($payment.currency)" -ForegroundColor White
    Write-Host ""

    # Step 5: Verify order
    Write-Host "[STEP 5] Verifying order details..." -ForegroundColor Yellow
    $orderDetails = Invoke-RestMethod -Uri "$ORDER_URL/v1/orders/$($order.order_id)" -Method Get
    Write-Host "[SUCCESS] Order verified!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Order Summary:" -ForegroundColor Cyan
    Write-Host "  Order ID: $($orderDetails.id)" -ForegroundColor White
    Write-Host "  Customer ID: $($orderDetails.customer_id)" -ForegroundColor White
    Write-Host "  Status: $($orderDetails.status)" -ForegroundColor White
    Write-Host "  Payment Status: $($orderDetails.payment_status)" -ForegroundColor White
    Write-Host "  Order Total: `$$($orderDetails.order_total)" -ForegroundColor White
    Write-Host "  Tax: `$$($orderDetails.tax)" -ForegroundColor White
    Write-Host "  Shipping: `$$($orderDetails.shipping)" -ForegroundColor White
    Write-Host "  Created: $($orderDetails.created_at)" -ForegroundColor White
    Write-Host ""
    Write-Host "Order Items:" -ForegroundColor Cyan
    $orderDetails.items | ForEach-Object {
        $itemSubtotal = [math]::Round(([decimal]$_.unit_price * $_.quantity), 2)
        Write-Host "  - $($_.name) ($($_.sku))" -ForegroundColor White
        Write-Host "    Quantity: $($_.quantity)" -ForegroundColor Gray
        Write-Host "    Unit Price: `$$($_.unit_price)" -ForegroundColor Gray
        Write-Host "    Subtotal: `$$itemSubtotal" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  [SUCCESS] ORDER PLACED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "[ERROR] Failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
} finally {
    Write-Host "[INFO] Stopping port-forwards..." -ForegroundColor Gray
    $portForwards | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}
