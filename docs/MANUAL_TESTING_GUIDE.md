# Manual Testing Guide - ECI Microservices

## Prerequisites

- Docker Desktop running
- All services started from `eci-microservices` directory
- Postman or similar REST client (optional)
- PowerShell terminal

---

## Step-by-Step Manual Testing

### 1. Start All Services

```powershell
cd eci-microservices
docker-compose up -d

# Wait for services to be healthy (30 seconds)
Start-Sleep -Seconds 30

# Check all containers are running
docker-compose ps
```

**Expected Output:** All 10 containers (5 services + 5 databases) should show "Up" status

---

### 2. Verify Health Endpoints

Test each service health endpoint:

```powershell
# Catalog Service
Invoke-RestMethod http://localhost:8090/health

# Inventory Service
Invoke-RestMethod http://localhost:8081/health

# Order Service
Invoke-RestMethod http://localhost:8082/health

# Payment Service
Invoke-RestMethod http://localhost:8086/health

# Shipping Service
Invoke-RestMethod http://localhost:8085/health
```

**Expected:** All should return healthy status with 200 OK

---

### 3. Seed Databases (First Time Only)

```powershell
# Seed Catalog with 10 products
docker exec catalog-service npm run seed

# Seed Inventory with 6 warehouse records
docker exec inventory-service npm run seed
```

**Expected:** 
- Catalog: "10 products seeded successfully"
- Inventory: "6 inventory records seeded successfully"

---

### 4. Test Catalog Service

#### Browse All Products
```powershell
$products = Invoke-RestMethod -Uri "http://localhost:8090/api/products" -Method Get
$products | ConvertTo-Json -Depth 3
```

**Expected:** JSON array with 10 products

#### Get Product by ID
```powershell
$productId = $products[0].product_id
Invoke-RestMethod -Uri "http://localhost:8090/api/products/$productId" -Method Get
```

**Expected:** Single product details for LAPTOP-001

#### Search Products by Category
```powershell
Invoke-RestMethod -Uri "http://localhost:8090/api/products/search?category=Electronics" -Method Get
```

**Expected:** Array of electronics products

#### Get Product by SKU
```powershell
Invoke-RestMethod -Uri "http://localhost:8090/api/products/sku/LAPTOP-001" -Method Get
```

**Expected:** Product details for Gaming Laptop Pro

---

### 5. Test Inventory Service

#### Check Inventory Availability
```powershell
Invoke-RestMethod -Uri "http://localhost:8081/api/inventory/availability?sku=LAPTOP-001" -Method Get
```

**Expected:** JSON with available and reserved quantities

#### Get Inventory by SKU
```powershell
Invoke-RestMethod -Uri "http://localhost:8081/api/inventory/sku/LAPTOP-001" -Method Get
```

**Expected:** Array of inventory records across warehouses

#### Reserve Inventory
```powershell
$reserveBody = @{
    sku = "LAPTOP-001"
    quantity = 2
    order_id = "TEST-ORDER-$(Get-Random -Maximum 9999)"
} | ConvertTo-Json

$reservation = Invoke-RestMethod -Uri "http://localhost:8081/api/inventory/reserve" `
    -Method Post `
    -ContentType "application/json" `
    -Body $reserveBody

Write-Host "Reservation ID: $($reservation.reservation_id)" -ForegroundColor Green
$reservation | ConvertTo-Json
```

**Expected:** Reservation ID returned, inventory reduced

#### Release Reservation
```powershell
$releaseBody = @{
    reservation_id = $reservation.reservation_id
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8081/api/inventory/release" `
    -Method Post `
    -ContentType "application/json" `
    -Body $releaseBody
```

**Expected:** Success message, inventory restored

---

### 6. Test Order Service

#### Create Order
```powershell
$orderBody = @{
    user_id = 1001
    items = @(
        @{ product_id = 1; quantity = 2; price = 1299.99 },
        @{ product_id = 2; quantity = 1; price = 799.99 }
    )
} | ConvertTo-Json

$order = Invoke-RestMethod -Uri "http://localhost:8082/orders/" `
    -Method Post `
    -ContentType "application/json" `
    -Body $orderBody

Write-Host "Order ID: $($order.order_id)" -ForegroundColor Green
Write-Host "Order Total: `$$($order.total_amount)" -ForegroundColor Green
$order | ConvertTo-Json -Depth 3
```

**Expected:** Order created with CONFIRMED status, total calculated with tax

#### Get Order by ID
```powershell
$orderId = $order.order_id
Invoke-RestMethod -Uri "http://localhost:8082/orders/$orderId" -Method Get
```

**Expected:** Complete order details including items

#### List Orders for User
```powershell
Invoke-RestMethod -Uri "http://localhost:8082/orders/?user_id=1001" -Method Get
```

**Expected:** Array of orders for user 1001

---

### 7. Test Payment Service

#### Create Payment
```powershell
$paymentBody = @{
    order_id = $order.order_id
    user_id = 1001
    amount = [decimal]$order.total_amount
    currency = "INR"
    payment_method = "CREDIT_CARD"
} | ConvertTo-Json

$idempotencyKey = [Guid]::NewGuid().ToString()
$headers = @{
    "Idempotency-Key" = $idempotencyKey
}

$payment = Invoke-RestMethod -Uri "http://localhost:8086/payments/" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $headers `
    -Body $paymentBody

Write-Host "Payment ID: $($payment.payment_id)" -ForegroundColor Green
Write-Host "Transaction ID: $($payment.transaction_id)" -ForegroundColor Green
$payment | ConvertTo-Json -Depth 3
```

**Expected:** Payment created with PENDING status, transaction ID generated

#### Get Payment by ID
```powershell
$paymentId = $payment.payment_id
Invoke-RestMethod -Uri "http://localhost:8086/payments/$paymentId" -Method Get
```

**Expected:** Payment details with transaction history

#### Check Payment by Order ID
```powershell
Invoke-RestMethod -Uri "http://localhost:8086/payments/order/$($order.order_id)" -Method Get
```

**Expected:** Payment details for the order

#### Test Idempotency (Retry Same Request)
```powershell
$headers = @{
    "Idempotency-Key" = $idempotencyKey
}

$retryPayment = Invoke-RestMethod -Uri "http://localhost:8086/payments/" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $headers `
    -Body $paymentBody

Write-Host "Same Payment ID: $($retryPayment.payment_id)" -ForegroundColor Yellow
Write-Host "Idempotency Working: $(if($payment.payment_id -eq $retryPayment.payment_id){'YES'}else{'NO'})" -ForegroundColor $(if($payment.payment_id -eq $retryPayment.payment_id){'Green'}else{'Red'})
```

**Expected:** Same payment ID returned, no duplicate payment created

#### Charge Payment
```powershell
$chargeBody = @{
    authorization_code = "AUTH-$(Get-Random -Maximum 999999)"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8086/payments/$paymentId/charge" `
    -Method Post `
    -ContentType "application/json" `
    -Body $chargeBody
```

**Expected:** Payment status changed to COMPLETED, captured_at timestamp set

---

### 8. Test Shipping Service

#### Create Shipment
```powershell
$shipmentBody = @{
    order_id = $order.order_id
    user_id = 1001
    address = @{
        street = "123 Main Street"
        city = "Mumbai"
        state = "Maharashtra"
        postal_code = "400001"
        country = "India"
    }
} | ConvertTo-Json

$shipment = Invoke-RestMethod -Uri "http://localhost:8085/shipments/" `
    -Method Post `
    -ContentType "application/json" `
    -Body $shipmentBody

Write-Host "Shipment ID: $($shipment.shipment_id)" -ForegroundColor Green
Write-Host "Tracking Number: $($shipment.tracking_number)" -ForegroundColor Green
$shipment | ConvertTo-Json -Depth 3
```

**Expected:** Shipment created with PENDING status, tracking number generated

#### Track Shipment
```powershell
$shipmentId = $shipment.shipment_id
Invoke-RestMethod -Uri "http://localhost:8085/shipments/$shipmentId" -Method Get
```

**Expected:** Shipment details with tracking information

#### Update Shipment Status
```powershell
$updateBody = @{
    status = "IN_TRANSIT"
    notes = "Package picked up by courier"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8085/shipments/$shipmentId/status" `
    -Method Put `
    -ContentType "application/json" `
    -Body $updateBody
```

**Expected:** Status updated to IN_TRANSIT

#### Get Shipments by Order ID
```powershell
Invoke-RestMethod -Uri "http://localhost:8085/shipments/order/$($order.order_id)" -Method Get
```

**Expected:** Array of shipments for the order

---

## Verification Checklist

### Database-Per-Service Pattern ✓

Verify each service has its own database:

```powershell
# Check databases exist
docker exec catalog-mysql mysql -ptoor -e "SHOW DATABASES;"
docker exec inventory-mysql mysql -ptoor -e "SHOW DATABASES;"
docker exec order-mysql mysql -ptoor -e "SHOW DATABASES;"
docker exec payment-postgres psql -U postgres -c "\l"
docker exec shipping-postgres psql -U postgres -c "\l"
```

**Expected:** Each service should have its own database (catalog_db, inventory_db, order_db, payment_db, shipping_db)

### Inter-Service Communication ✓

Verify Order service communicates with other services:

```powershell
# Check Order service logs
docker logs order-service --tail 50

# Look for successful API calls to:
# - Catalog Service (product validation)
# - Inventory Service (reservation)
# - Payment Service (payment processing)
```

**Expected:** No connection errors, successful API responses

### Data Consistency ✓

After creating an order:

```powershell
# 1. Check inventory was reserved
Invoke-RestMethod -Uri "http://localhost:8081/api/inventory/availability?sku=LAPTOP-001" -Method Get

# 2. Check order exists
Invoke-RestMethod -Uri "http://localhost:8082/orders/$orderId" -Method Get

# 3. Check payment was created
Invoke-RestMethod -Uri "http://localhost:8086/payments/order/$orderId" -Method Get

# 4. Check shipment was created
Invoke-RestMethod -Uri "http://localhost:8085/shipments/order/$orderId" -Method Get
```

**Expected:** Data is consistent across all services

---

## Performance Testing

### Response Time Check

```powershell
Measure-Command { Invoke-RestMethod http://localhost:8090/api/products }
Measure-Command { Invoke-RestMethod http://localhost:8081/api/inventory/availability?sku=LAPTOP-001 }
```

**Expected:** < 500ms for simple queries

### Concurrent Requests

```powershell
# Test 10 concurrent product requests
1..10 | ForEach-Object -Parallel {
    Invoke-RestMethod http://localhost:8090/api/products
}
```

**Expected:** All requests complete successfully

---

## Error Handling Tests

### Test Invalid Product ID
```powershell
try {
    Invoke-RestMethod -Uri "http://localhost:8090/api/products/invalid-id" -Method Get
} catch {
    Write-Host "Expected Error: $($_.Exception.Message)" -ForegroundColor Yellow
}
```

**Expected:** 404 Not Found

### Test Insufficient Inventory
```powershell
$invalidReserve = @{
    sku = "LAPTOP-001"
    quantity = 99999  # More than available
    order_id = "TEST-FAIL"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8081/api/inventory/reserve" `
        -Method Post `
        -ContentType "application/json" `
        -Body $invalidReserve
} catch {
    Write-Host "Expected Error: Insufficient inventory" -ForegroundColor Yellow
}
```

**Expected:** 400 Bad Request with appropriate error message

### Test Invalid Payment Amount
```powershell
$invalidPayment = @{
    order_id = 999999  # Non-existent order
    user_id = 1001
    amount = -100  # Negative amount
    currency = "INR"
    payment_method = "CREDIT_CARD"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8086/payments/" `
        -Method Post `
        -ContentType "application/json" `
        -Body $invalidPayment
} catch {
    Write-Host "Expected Error: Invalid amount or order" -ForegroundColor Yellow
}
```

**Expected:** 400 Bad Request

---

## Clean Up After Testing

```powershell
# Stop all services
docker-compose down

# Remove volumes (optional - deletes all data)
docker-compose down -v

# Remove unused containers
docker system prune -f
```

---

## Assignment Requirements Verification

### ✅ Microservices Architecture
- [x] 5 independent microservices
- [x] Each service has its own codebase
- [x] Each service in separate git repository

### ✅ Database-Per-Service Pattern
- [x] No shared databases
- [x] No cross-database joins
- [x] Data accessed only through service APIs

### ✅ RESTful APIs
- [x] All services expose REST endpoints
- [x] Proper HTTP methods (GET, POST, PUT, DELETE)
- [x] JSON request/response format

### ✅ Docker Containerization
- [x] Each service has Dockerfile
- [x] Services run in Docker containers
- [x] docker-compose.yml for orchestration

### ✅ Health Checks
- [x] All services implement /health endpoint
- [x] Health checks configured in docker-compose

### ✅ Inter-Service Communication
- [x] Order service coordinates other services
- [x] Services communicate via HTTP APIs
- [x] No direct database access between services

### ✅ Error Handling
- [x] Proper HTTP status codes
- [x] Meaningful error messages
- [x] Validation of inputs

### ✅ Data Seeding
- [x] Sample data available for testing
- [x] Seed scripts for catalog and inventory

### ✅ Testing
- [x] E2E test script provided
- [x] Manual testing guide available
- [x] All 11 workflow steps working

---

## Troubleshooting

### Service Won't Start
```powershell
# Check logs
docker logs <service-name>

# Restart specific service
docker-compose restart <service-name>
```

### Database Connection Issues
```powershell
# Check database is running
docker ps | Select-String "mysql|postgres"

# Verify database credentials in docker-compose.yml
```

### Port Already in Use
```powershell
# Find process using port
netstat -ano | findstr :<port>

# Kill process
taskkill /PID <pid> /F
```

---

**Testing Time Estimate:** 30-45 minutes for complete manual testing
**Prerequisites:** All services running, databases seeded
**Outcome:** Verify all microservices work independently and as an integrated system
