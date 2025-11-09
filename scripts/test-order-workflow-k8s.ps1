# ECI Platform - Order Workflow Test (K8s Version)
# This simulates a real customer journey: Browse -> Order -> Pay -> Ship

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  ECI Platform - Order Workflow Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Base URLs (local port-forwards)
$CATALOG_URL = "http://localhost:9090"
$INVENTORY_URL = "http://localhost:9091"
$ORDER_URL = "http://localhost:9082"
$PAYMENT_URL = "http://localhost:9086"
$SHIPPING_URL = "http://localhost:9085"

# Test configuration
$TIMESTAMP = Get-Date -Format 'yyyyMMddHHmmss'
$IDEMPOTENCY_KEY = "test-$TIMESTAMP"

Write-Host "[INFO] Starting port-forwards..." -ForegroundColor Yellow
Write-Host ""

# Start port-forwards in background
$portForwards = @()
$portForwards += Start-Process powershell -ArgumentList "-Command", "kubectl port-forward -n eci svc/catalog-service 9090:8080" -WindowStyle Hidden -PassThru
$portForwards += Start-Process powershell -ArgumentList "-Command", "kubectl port-forward -n eci svc/inventory-service 9091:8081" -WindowStyle Hidden -PassThru
$portForwards += Start-Process powershell -ArgumentList "-Command", "kubectl port-forward -n eci svc/order-service 9082:8000" -WindowStyle Hidden -PassThru
$portForwards += Start-Process powershell -ArgumentList "-Command", "kubectl port-forward -n eci svc/payment-service 9086:8006" -WindowStyle Hidden -PassThru
$portForwards += Start-Process powershell -ArgumentList "-Command", "kubectl port-forward -n eci svc/shipping-service 9085:8005" -WindowStyle Hidden -PassThru

Write-Host "[INFO] Waiting for port-forwards to establish..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Write-Host ""

# Test results tracking
$testsPassed = 0
$testsFailed = 0

# Variables to store created resources
$ORDER_ID = $null
$PAYMENT_ID = $null
$SHIPMENT_ID = $null
$TRACKING_NUMBER = $null
$SELECTED_SKU = $null
$SELECTED_PRODUCT = $null

try {
    # Step 1: Browse Products
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 1: Browse Products (Catalog Service)" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    try {
        $productList = Invoke-RestMethod -Uri "$CATALOG_URL/v1/products?limit=5" -Method Get
        $productCount = ($productList | Measure-Object).Count
        Write-Host "[PASS] Retrieved $productCount products" -ForegroundColor Green
        
        # Display first few products
        Write-Host "`nAvailable Products:" -ForegroundColor White
        $productList | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.sku): $($_.name) ($$($_.price))" -ForegroundColor Gray
        }
        
        # Select first product for order
        $SELECTED_PRODUCT = $productList[0]
        $SELECTED_SKU = $SELECTED_PRODUCT.sku
        Write-Host "`n[INFO] Selected product: $($SELECTED_PRODUCT.name) ($SELECTED_SKU)" -ForegroundColor Cyan
        $testsPassed++
    } catch {
        Write-Host "[FAIL] Failed to retrieve products: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
        throw
    }
    Write-Host ""

    # Step 2: Check Inventory
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 2: Check Inventory (Inventory Service)" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    try {
        $inventory = Invoke-RestMethod -Uri "$INVENTORY_URL/v1/inventory/$SELECTED_SKU" -Method Get
        $availableQty = ($inventory | Measure-Object -Property on_hand -Sum).Sum
        Write-Host "[PASS] Inventory available: $availableQty units across $($inventory.Count) warehouse(s)" -ForegroundColor Green
        
        # Display warehouse details
        Write-Host "`nWarehouse Stock:" -ForegroundColor White
        $inventory | ForEach-Object {
            Write-Host "  - $($_.warehouse_id): $($_.on_hand) units (Reserved: $($_.reserved))" -ForegroundColor Gray
        }
        
        $WAREHOUSE_ID = $inventory[0].warehouse_id
        $testsPassed++
    } catch {
        Write-Host "[FAIL] Failed to check inventory: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
        throw
    }
    Write-Host ""

    # Step 3: Create Order
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 3: Create Order (Order Service)" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    try {
        $orderQuantity = 2
        $unitPrice = [decimal]$SELECTED_PRODUCT.price
        $subtotal = $unitPrice * $orderQuantity
        $shipping = 99.99
        $total = $subtotal + $shipping
        
        # Generate a simple integer product ID from hash of UUID
        $productIdInt = [Math]::Abs(($SELECTED_PRODUCT.product_id.GetHashCode())) % 999999 + 1
        
        $orderBody = @{
            customer_id = 1
            items = @(
                @{
                    product_id = $productIdInt
                    sku = $SELECTED_SKU
                    name = $SELECTED_PRODUCT.name
                    quantity = $orderQuantity
                    unit_price = $unitPrice
                }
            )
            shipping = $shipping
        } | ConvertTo-Json -Depth 4

        $headers = @{
            "Content-Type" = "application/json"
            "Idempotency-Key" = "$IDEMPOTENCY_KEY-order"
        }

        $order = Invoke-RestMethod -Uri "$ORDER_URL/v1/orders" -Method Post -Body $orderBody -Headers $headers
        $ORDER_ID = $order.order_id
        
        Write-Host "[PASS] Order created successfully" -ForegroundColor Green
        Write-Host "  Order ID: $ORDER_ID" -ForegroundColor White
        Write-Host "  Status: $($order.status)" -ForegroundColor White
        Write-Host "  Subtotal: $subtotal" -ForegroundColor White
        Write-Host "  Shipping: $shipping" -ForegroundColor White
        Write-Host "  Total: $([math]::Round($order.total_amount, 2))" -ForegroundColor White
        $testsPassed++
    } catch {
        Write-Host "[FAIL] Failed to create order: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
        throw
    }
    Write-Host ""

    # Step 4: Process Payment
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 4: Process Payment (Payment Service)" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    try {
        $paymentBody = @{
            order_id = [int]$ORDER_ID
            user_id = 1
            amount = [math]::Round($total, 2)
            currency = "USD"
            payment_method = "CREDIT_CARD"
            reference = "test-payment-$TIMESTAMP"
        } | ConvertTo-Json -Depth 4

        $headers = @{
            "Content-Type" = "application/json"
            "Idempotency-Key" = "$IDEMPOTENCY_KEY-payment"
        }

        $payment = Invoke-RestMethod -Uri "$PAYMENT_URL/v1/payments" -Method Post -Body $paymentBody -Headers $headers
        $PAYMENT_ID = $payment.payment_id
        
        Write-Host "[PASS] Payment processed successfully" -ForegroundColor Green
        Write-Host "  Payment ID: $PAYMENT_ID" -ForegroundColor White
        Write-Host "  Status: $($payment.status)" -ForegroundColor White
        Write-Host "  Amount: $($payment.amount) $($payment.currency)" -ForegroundColor White
        Write-Host "  Method: $($payment.payment_method)" -ForegroundColor White
        $testsPassed++
    } catch {
        Write-Host "[FAIL] Failed to process payment: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
        throw
    }
    Write-Host ""

    # Step 5: Create Shipment
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 5: Create Shipment (Shipping Service)" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    try {
        $shipmentBody = @{
            order_id = [int]$ORDER_ID
            carrier = "DHL"
            shipping_address = @{
                street = "123 Main Street"
                city = "Bangalore"
                state = "Karnataka"
                zip_code = "560001"
                country = "India"
            }
        } | ConvertTo-Json -Depth 4

        $headers = @{
            "Content-Type" = "application/json"
        }

        $shipment = Invoke-RestMethod -Uri "$SHIPPING_URL/v1/shipments" -Method Post -Body $shipmentBody -Headers $headers
        $SHIPMENT_ID = $shipment.shipment_id
        $TRACKING_NUMBER = $shipment.tracking_number
        
        Write-Host "[PASS] Shipment created successfully" -ForegroundColor Green
        Write-Host "  Shipment ID: $SHIPMENT_ID" -ForegroundColor White
        Write-Host "  Tracking Number: $TRACKING_NUMBER" -ForegroundColor White
        Write-Host "  Status: $($shipment.status)" -ForegroundColor White
        Write-Host "  Carrier: $($shipment.carrier)" -ForegroundColor White
        $testsPassed++
    } catch {
        Write-Host "[FAIL] Failed to create shipment: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
        throw
    }
    Write-Host ""

    # Step 6: Track Shipment
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 6: Track Shipment (Shipping Service)" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    try {
        $tracking = Invoke-RestMethod -Uri "$SHIPPING_URL/v1/shipments/tracking/$TRACKING_NUMBER" -Method Get
        
        Write-Host "[PASS] Shipment tracked successfully" -ForegroundColor Green
        Write-Host "  Status: $($tracking.status)" -ForegroundColor White
        Write-Host "  Current Location: $($tracking.current_location)" -ForegroundColor White
        Write-Host "  Estimated Delivery: $($tracking.estimated_delivery)" -ForegroundColor White
        $testsPassed++
    } catch {
        Write-Host "[FAIL] Failed to track shipment: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
    }
    Write-Host ""

    # Step 7: Update Shipment Status
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 7: Update Shipment Status" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    try {
        $statusBody = @{
            status = "IN_TRANSIT"
            location = "Mumbai Sorting Center"
            description = "Package picked up and in transit to destination"
        } | ConvertTo-Json

        $headers = @{
            "Content-Type" = "application/json"
        }

        $statusUpdate = Invoke-RestMethod -Uri "$SHIPPING_URL/v1/shipments/$SHIPMENT_ID/status" -Method Patch -Body $statusBody -Headers $headers
        
        Write-Host "[PASS] Shipment status updated successfully" -ForegroundColor Green
        Write-Host "  New Status: $($statusUpdate.status)" -ForegroundColor White
        Write-Host "  Location: $($statusUpdate.current_location)" -ForegroundColor White
        $testsPassed++
    } catch {
        Write-Host "[FAIL] Failed to update shipment status: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
    }
    Write-Host ""

    # Step 8: Verify Order Status
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "STEP 8: Verify Order Status" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    try {
        $orderDetails = Invoke-RestMethod -Uri "$ORDER_URL/v1/orders/$ORDER_ID" -Method Get
        
        Write-Host "[PASS] Order details retrieved" -ForegroundColor Green
        Write-Host "  Order ID: $($orderDetails.order_id)" -ForegroundColor White
        Write-Host "  Status: $($orderDetails.status)" -ForegroundColor White
        Write-Host "  Items: $($orderDetails.items.Count)" -ForegroundColor White
        Write-Host "  Total: $([math]::Round($orderDetails.total_amount, 2))" -ForegroundColor White
        $testsPassed++
    } catch {
        Write-Host "[FAIL] Failed to retrieve order details: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
    }
    Write-Host ""

} finally {
    # Cleanup: Stop port-forwards
    Write-Host "[INFO] Stopping port-forwards..." -ForegroundColor Gray
    $portForwards | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    Write-Host ""
}

# Final Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  ORDER WORKFLOW TEST SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($testsPassed + $testsFailed)" -ForegroundColor White
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "[SUCCESS] All order workflow steps completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Order Details:" -ForegroundColor Cyan
    Write-Host "  Order ID: $ORDER_ID" -ForegroundColor White
    Write-Host "  Payment ID: $PAYMENT_ID" -ForegroundColor White
    Write-Host "  Shipment ID: $SHIPMENT_ID" -ForegroundColor White
    Write-Host "  Tracking Number: $TRACKING_NUMBER" -ForegroundColor White
    Write-Host "  Product: $($SELECTED_PRODUCT.name)" -ForegroundColor White
    Write-Host "  SKU: $SELECTED_SKU" -ForegroundColor White
    Write-Host ""
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed. Review the output above." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
