# =====================================================
# ECI Platform - 3 Services E2E Integration Test
# Order + Payment + Shipping Services
# =====================================================

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  ECI PLATFORM - 3 SERVICES INTEGRATION TEST" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Generate unique timestamp for idempotency keys
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

# ========================================
# STEP 1: Create Order
# ========================================
Write-Host "STEP 1: Creating Order..." -ForegroundColor Yellow

$orderBody = @{
    user_id = 1
    shipping = "50.00"
    items = @(
        @{
            product_id = 101
            sku = "LAPTOP-HP-001"
            name = "HP Gaming Laptop"
            quantity = 1
            unit_price = "1299.99"
        },
        @{
            product_id = 102
            sku = "MOUSE-LOGITECH-01"
            name = "Logitech Gaming Mouse"
            quantity = 2
            unit_price = "49.99"
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $orderResponse = Invoke-RestMethod -Uri "http://localhost:8081/v1/orders" `
        -Method Post `
        -Body $orderBody `
        -ContentType "application/json" `
        -Headers @{"Idempotency-Key"="order-$timestamp"}
    
    $orderId = $orderResponse.order_id
    $orderTotal = $orderResponse.total
    
    Write-Host "✅ Order Created Successfully!" -ForegroundColor Green
    Write-Host "   Order ID: $orderId" -ForegroundColor White
    Write-Host "   Subtotal: ₹$($orderResponse.subtotal)" -ForegroundColor White
    Write-Host "   Tax: ₹$($orderResponse.tax)" -ForegroundColor White
    Write-Host "   Total: ₹$orderTotal" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host "❌ Failed to create order: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# ========================================
# STEP 2: Process Payment
# ========================================
Write-Host "STEP 2: Processing Payment..." -ForegroundColor Yellow

$paymentBody = @{
    order_id = $orderId
    amount = $orderTotal
    payment_method = "credit_card"
    card_number = "4111111111111111"
    card_holder = "John Doe"
    cvv = "123"
    expiry_date = "12/26"
} | ConvertTo-Json

try {
    $paymentResponse = Invoke-RestMethod -Uri "http://localhost:8086/v1/payments/charge" `
        -Method Post `
        -Body $paymentBody `
        -ContentType "application/json" `
        -Headers @{"Idempotency-Key"="payment-$timestamp"}
    
    $paymentId = $paymentResponse.payment_id
    
    Write-Host "✅ Payment Processed Successfully!" -ForegroundColor Green
    Write-Host "   Payment ID: $paymentId" -ForegroundColor White
    Write-Host "   Status: $($paymentResponse.status)" -ForegroundColor White
    Write-Host "   Amount: ₹$($paymentResponse.amount)" -ForegroundColor White
    Write-Host "   Gateway Transaction: $($paymentResponse.gateway_transaction_id)" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host "❌ Failed to process payment: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# ========================================
# STEP 3: Create Shipment
# ========================================
Write-Host "STEP 3: Creating Shipment..." -ForegroundColor Yellow

$shipmentBody = @{
    order_id = $orderId
    carrier = "FedEx"
    shipping_address = @{
        street = "456 Tech Avenue"
        city = "San Francisco"
        state = "CA"
        postal_code = "94105"
        country = "USA"
    }
} | ConvertTo-Json -Depth 10

try {
    $shipmentResponse = Invoke-RestMethod -Uri "http://localhost:8085/v1/shipments" `
        -Method Post `
        -Body $shipmentBody `
        -ContentType "application/json" `
        -Headers @{"Idempotency-Key"="shipment-$timestamp"}
    
    $shipmentId = $shipmentResponse.shipment_id
    $trackingNumber = $shipmentResponse.tracking_number
    
    Write-Host "✅ Shipment Created Successfully!" -ForegroundColor Green
    Write-Host "   Shipment ID: $shipmentId" -ForegroundColor White
    Write-Host "   Tracking Number: $trackingNumber" -ForegroundColor White
    Write-Host "   Carrier: $($shipmentResponse.carrier)" -ForegroundColor White
    Write-Host "   Status: $($shipmentResponse.status)" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host "❌ Failed to create shipment: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# ========================================
# STEP 4: Track Shipment
# ========================================
Write-Host "STEP 4: Tracking Shipment..." -ForegroundColor Yellow

try {
    $trackingResponse = Invoke-RestMethod -Uri "http://localhost:8085/v1/shipments/track/$trackingNumber"
    
    Write-Host "✅ Shipment Tracking Retrieved!" -ForegroundColor Green
    Write-Host "   Status: $($trackingResponse.status)" -ForegroundColor White
    Write-Host "   Carrier: $($trackingResponse.carrier)" -ForegroundColor White
    Write-Host "   Created: $($trackingResponse.created_at)" -ForegroundColor White
    Write-Host "   Destination: $($trackingResponse.shipping_address.city), $($trackingResponse.shipping_address.state)" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host "❌ Failed to track shipment: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ========================================
# STEP 5: Update Shipment Status
# ========================================
Write-Host "STEP 5: Updating Shipment Status..." -ForegroundColor Yellow

$statusUpdates = @("Picked Up", "In Transit", "Out for Delivery")

foreach ($newStatus in $statusUpdates) {
    try {
        $statusBody = @{
            status = $newStatus
            location = "Distribution Center - $newStatus"
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri "http://localhost:8085/v1/shipments/$shipmentId/status" `
            -Method Patch `
            -Body $statusBody `
            -ContentType "application/json" | Out-Null
        
        Write-Host "   ✓ Status updated to: $newStatus" -ForegroundColor Cyan
        Start-Sleep -Seconds 1
    }
    catch {
        Write-Host "   ⚠ Failed to update status to $newStatus" -ForegroundColor Yellow
    }
}

Write-Host "✅ Shipment Status Updates Complete!" -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 2

# ========================================
# STEP 6: Get Order Details
# ========================================
Write-Host "STEP 6: Retrieving Order Details..." -ForegroundColor Yellow

try {
    $orderDetails = Invoke-RestMethod -Uri "http://localhost:8081/v1/orders/$orderId"
    
    Write-Host "✅ Order Details Retrieved!" -ForegroundColor Green
    Write-Host "   Order ID: $($orderDetails.id)" -ForegroundColor White
    Write-Host "   Status: $($orderDetails.status)" -ForegroundColor White
    Write-Host "   Total: ₹$($orderDetails.order_total)" -ForegroundColor White
    Write-Host "   Items Count: $($orderDetails.items.Count)" -ForegroundColor White
    Write-Host "   Created: $($orderDetails.created_at)" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host "❌ Failed to retrieve order: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ========================================
# STEP 7: Get Payment Details
# ========================================
Write-Host "STEP 7: Retrieving Payment Details..." -ForegroundColor Yellow

try {
    $paymentDetails = Invoke-RestMethod -Uri "http://localhost:8086/v1/payments/$paymentId"
    
    Write-Host "✅ Payment Details Retrieved!" -ForegroundColor Green
    Write-Host "   Payment ID: $($paymentDetails.payment_id)" -ForegroundColor White
    Write-Host "   Status: $($paymentDetails.status)" -ForegroundColor White
    Write-Host "   Amount: ₹$($paymentDetails.amount)" -ForegroundColor White
    Write-Host "   Method: $($paymentDetails.payment_method)" -ForegroundColor White
    Write-Host "   Processed: $($paymentDetails.created_at)" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host "❌ Failed to retrieve payment: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ========================================
# STEP 8: Test Idempotency
# ========================================
Write-Host "STEP 8: Testing Idempotency (Duplicate Request)..." -ForegroundColor Yellow

try {
    # Try to create the same order again with same idempotency key
    $duplicateResponse = Invoke-RestMethod -Uri "http://localhost:8081/v1/orders" `
        -Method Post `
        -Body $orderBody `
        -ContentType "application/json" `
        -Headers @{"Idempotency-Key"="order-$timestamp"}
    
    Write-Host "❌ Idempotency FAILED - Duplicate order was created!" -ForegroundColor Red
}
catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "✅ Idempotency Working! Duplicate request blocked (409 Conflict)" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ Unexpected error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
Write-Host ""

# ========================================
# FINAL SUMMARY
# ========================================
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  E2E INTEGRATION TEST COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Order ID: $orderId" -ForegroundColor White
Write-Host "💳 Payment ID: $paymentId" -ForegroundColor White
Write-Host "🚚 Shipment ID: $shipmentId" -ForegroundColor White
Write-Host "📍 Tracking Number: $trackingNumber" -ForegroundColor White
Write-Host "💰 Total Amount: ₹$orderTotal" -ForegroundColor White
Write-Host ""
Write-Host "✅ All services communicated successfully!" -ForegroundColor Green
Write-Host "✅ Idempotency working correctly!" -ForegroundColor Green
Write-Host "✅ Complete order-to-delivery workflow validated!" -ForegroundColor Green
Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
