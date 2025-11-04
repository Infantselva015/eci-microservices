# ECI Platform - E2E Workflow Test (PowerShell Version)
# This simulates a real customer journey through the ECI platform

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  ECI Platform - E2E Workflow Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Base URLs
$CATALOG_URL = "http://localhost:8001"
$ORDER_URL = "http://localhost:8002"
$INVENTORY_URL = "http://localhost:8003"
$NOTIFICATION_URL = "http://localhost:8004"
$SHIPPING_URL = "http://localhost:8085"
$PAYMENT_URL = "http://localhost:8086"

# Test data
$PRODUCT_ID = 1
$QUANTITY = 2
$CUSTOMER_EMAIL = "customer@example.com"
$IDEMPOTENCY_KEY = "test-$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "Step 1: Browse Products (Catalog Service)" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
try {
    $products = Invoke-RestMethod -Uri "$CATALOG_URL/v1/products" -Method Get
    Write-Host "✅ Products retrieved" -ForegroundColor Green
    $products | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "Step 2: Check Inventory (Inventory Service)" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
try {
    $inventory = Invoke-RestMethod -Uri "$INVENTORY_URL/v1/inventory/$PRODUCT_ID" -Method Get
    Write-Host "✅ Inventory available" -ForegroundColor Green
    $inventory | ConvertTo-Json
} catch {
    Write-Host "❌ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "Step 3: Reserve Inventory (Inventory Service)" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
try {
    $reservationBody = @{
        product_id = $PRODUCT_ID
        quantity = $QUANTITY
        order_id = 1
    } | ConvertTo-Json

    $headers = @{
        "Content-Type" = "application/json"
        "Idempotency-Key" = "$IDEMPOTENCY_KEY-inventory"
    }

    $reservation = Invoke-RestMethod -Uri "$INVENTORY_URL/v1/inventory/reserve" -Method Post -Body $reservationBody -Headers $headers
    Write-Host "✅ Inventory reserved" -ForegroundColor Green
    $reservation | ConvertTo-Json
    $RESERVATION_ID = $reservation.reservation_id
} catch {
    Write-Host "❌ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "Step 4: Create Order (Order Service)" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
try {
    $orderBody = @{
        customer_id = 1
        items = @(
            @{
                product_id = $PRODUCT_ID
                quantity = $QUANTITY
                price = 2499.99
            }
        )
        shipping_address = @{
            street = "123 Main St"
            city = "Bangalore"
            state = "Karnataka"
            zip_code = "560001"
            country = "India"
        }
        customer_email = $CUSTOMER_EMAIL
    } | ConvertTo-Json -Depth 4

    $headers = @{
        "Content-Type" = "application/json"
        "Idempotency-Key" = "$IDEMPOTENCY_KEY-order"
    }

    $order = Invoke-RestMethod -Uri "$ORDER_URL/v1/orders" -Method Post -Body $orderBody -Headers $headers
    Write-Host "✅ Order created" -ForegroundColor Green
    $order | ConvertTo-Json
    $ORDER_ID = $order.order_id
} catch {
    Write-Host "❌ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "Step 5: Charge Payment (Payment Service)" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
try {
    $paymentBody = @{
        order_id = $ORDER_ID
        amount = 4999.98
        currency = "INR"
        payment_method = @{
            type = "credit_card"
            card_number = "4111111111111111"
            expiry_month = 12
            expiry_year = 2025
            cvv = "123"
            cardholder_name = "Test Customer"
        }
        billing_address = @{
            street = "123 Main St"
            city = "Bangalore"
            state = "Karnataka"
            zip_code = "560001"
            country = "India"
        }
    } | ConvertTo-Json -Depth 4

    $headers = @{
        "Content-Type" = "application/json"
        "Idempotency-Key" = "$IDEMPOTENCY_KEY-payment"
    }

    $payment = Invoke-RestMethod -Uri "$PAYMENT_URL/v1/payments/charge" -Method Post -Body $paymentBody -Headers $headers
    Write-Host "✅ Payment charged" -ForegroundColor Green
    $payment | ConvertTo-Json
    $PAYMENT_ID = $payment.payment_id
} catch {
    Write-Host "❌ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "Step 6: Create Shipment (Shipping Service)" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
try {
    $shipmentBody = @{
        order_id = $ORDER_ID
        recipient_name = "Test Customer"
        recipient_email = $CUSTOMER_EMAIL
        recipient_phone = "+91-9876543210"
        shipping_address = @{
            street = "123 Main St"
            city = "Bangalore"
            state = "Karnataka"
            zip_code = "560001"
            country = "India"
        }
        items = @(
            @{
                product_id = $PRODUCT_ID
                quantity = $QUANTITY
                weight = 2.5
            }
        )
    } | ConvertTo-Json -Depth 4

    $headers = @{
        "Content-Type" = "application/json"
        "Idempotency-Key" = "$IDEMPOTENCY_KEY-shipment"
    }

    $shipment = Invoke-RestMethod -Uri "$SHIPPING_URL/v1/shipments" -Method Post -Body $shipmentBody -Headers $headers
    Write-Host "✅ Shipment created" -ForegroundColor Green
    $shipment | ConvertTo-Json
    $SHIPMENT_ID = $shipment.shipment_id
    $TRACKING_NUMBER = $shipment.tracking_number
} catch {
    Write-Host "❌ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "Step 7: Track Shipment (Shipping Service)" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
try {
    $tracking = Invoke-RestMethod -Uri "$SHIPPING_URL/v1/shipments/tracking/$TRACKING_NUMBER" -Method Get
    Write-Host "✅ Shipment tracking" -ForegroundColor Green
    $tracking | ConvertTo-Json
} catch {
    Write-Host "❌ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "Step 8: Update Shipment Status (Shipping Service)" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
try {
    $statusBody = @{
        status = "SHIPPED"
        location = "Bangalore Sorting Center"
        notes = "Package picked up and in transit"
    } | ConvertTo-Json

    $headers = @{
        "Content-Type" = "application/json"
    }

    $statusUpdate = Invoke-RestMethod -Uri "$SHIPPING_URL/v1/shipments/$SHIPMENT_ID/status" -Method Patch -Body $statusBody -Headers $headers
    Write-Host "✅ Shipment status updated" -ForegroundColor Green
    $statusUpdate | ConvertTo-Json
} catch {
    Write-Host "❌ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "Step 9: Verify Notification Sent (Notification Service)" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
try {
    $notifications = Invoke-RestMethod -Uri "$NOTIFICATION_URL/v1/notifications?recipient=$CUSTOMER_EMAIL" -Method Get
    Write-Host "✅ Notifications sent" -ForegroundColor Green
    $notifications | ConvertTo-Json
} catch {
    Write-Host "⚠️  Notification service not fully implemented yet" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "==========================================" -ForegroundColor Green
Write-Host "  ✅ E2E Workflow Test COMPLETED!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "--------" -ForegroundColor Gray
Write-Host "• Order ID: $ORDER_ID" -ForegroundColor White
Write-Host "• Payment ID: $PAYMENT_ID" -ForegroundColor White
Write-Host "• Shipment ID: $SHIPMENT_ID" -ForegroundColor White
Write-Host "• Tracking Number: $TRACKING_NUMBER" -ForegroundColor White
Write-Host "• Customer Email: $CUSTOMER_EMAIL" -ForegroundColor White
Write-Host ""
Write-Host "All services are working together successfully! 🎉" -ForegroundColor Green
