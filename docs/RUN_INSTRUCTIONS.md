# Quick Start Guide - ECI Microservices Platform

## Prerequisites

- Docker Desktop installed and running
- Windows PowerShell (for running scripts)
- Minimum 4GB RAM available for Docker
- Ports available: 8090, 8081, 8082, 8086, 8085

---

## Starting the System

### 1. Start All Services

```powershell
cd "Final_Submission"
docker-compose up -d
```

**Expected Output:**
```
✔ Container catalog-mysql        Healthy
✔ Container inventory-mysql      Healthy
✔ Container order-mysql          Healthy
✔ Container payment-postgres     Healthy
✔ Container shipping-postgres    Healthy
✔ Container catalog-service      Healthy
✔ Container inventory-service    Healthy
✔ Container order-service        Healthy
✔ Container payment-service      Started
✔ Container shipping-service     Started
```

### 2. Seed Databases (First Time Only)

```powershell
# Seed Catalog with 10 products
docker exec catalog-service npm run seed

# Seed Inventory with 6 warehouse records
docker exec inventory-service npm run seed
```

### 3. Verify Services are Running

```powershell
docker-compose ps
```

All services should show status: `Up` or `Up (healthy)`

---

## Testing the System

### Run Complete E2E Test

```powershell
.\test-5-services-e2e.ps1
```

This will execute an 11-step end-to-end test covering:
- Health checks for all 5 services
- Product browsing
- Inventory checking and reservation
- Order creation
- Payment processing
- Shipment creation and tracking
- Status updates
- Idempotency validation

**Expected Result:** All steps should pass with green checkmarks ✅

---

## Accessing Services

### Service Endpoints

| Service | URL | Health Check |
|---------|-----|--------------|
| **Catalog** | http://localhost:8090 | http://localhost:8090/api/health |
| **Inventory** | http://localhost:8081 | http://localhost:8081/api/health |
| **Order** | http://localhost:8082 | http://localhost:8082/health |
| **Payment** | http://localhost:8086 | http://localhost:8086/health |
| **Shipping** | http://localhost:8085 | http://localhost:8085/health |

### Quick Health Check (All Services)

```powershell
# PowerShell script to check all services
@(8090, 8081, 8082, 8086, 8085) | ForEach-Object {
    $port = $_
    try {
        $response = Invoke-RestMethod "http://localhost:$port/health" -ErrorAction Stop
        Write-Host "✅ Port $port : HEALTHY" -ForegroundColor Green
    } catch {
        Write-Host "❌ Port $port : FAILED" -ForegroundColor Red
    }
}
```

---

## Common Operations

### View Service Logs

```powershell
# View logs for a specific service
docker logs catalog-service --tail 50
docker logs inventory-service --tail 50
docker logs order-service --tail 50
docker logs payment-service --tail 50
docker logs shipping-service --tail 50

# Follow logs in real-time
docker logs -f catalog-service
```

### Restart a Service

```powershell
# Restart single service
docker-compose restart catalog-service

# Restart all services
docker-compose restart
```

### Stop All Services

```powershell
docker-compose down
```

### Stop and Remove Volumes (Clean Reset)

```powershell
docker-compose down -v
# Note: This will delete all database data. You'll need to seed again.
```

---

## Sample API Calls

### 1. Browse Products (Catalog Service)

```powershell
Invoke-RestMethod -Uri "http://localhost:8090/api/products" -Method Get
```

### 2. Check Inventory

```powershell
Invoke-RestMethod -Uri "http://localhost:8081/api/inventory/availability?sku=LAPTOP-001" -Method Get
```

### 3. Reserve Inventory

```powershell
$reserveBody = @{
    sku = "LAPTOP-001"
    quantity = 2
    order_id = "TEST-ORDER-001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8081/api/inventory/reserve" `
    -Method Post `
    -ContentType "application/json" `
    -Body $reserveBody
```

### 4. Create Order

```powershell
$orderBody = @{
    user_id = 1001
    items = @(
        @{ product_id = 1; quantity = 2; price = 1299.99 },
        @{ product_id = 2; quantity = 1; price = 799.99 }
    )
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8082/orders/" `
    -Method Post `
    -ContentType "application/json" `
    -Body $orderBody
```

### 5. Process Payment

```powershell
$paymentBody = @{
    order_id = 1
    user_id = 1001
    amount = 3584.97
    currency = "INR"
    payment_method = "CREDIT_CARD"
} | ConvertTo-Json

$headers = @{
    "Idempotency-Key" = "$(New-Guid)"
}

Invoke-RestMethod -Uri "http://localhost:8086/payments/" `
    -Method Post `
    -ContentType "application/json" `
    -Headers $headers `
    -Body $paymentBody
```

### 6. Create Shipment

```powershell
$shipmentBody = @{
    order_id = 1
    user_id = 1001
    address = @{
        street = "123 Main St"
        city = "Mumbai"
        state = "MH"
        postal_code = "400001"
        country = "India"
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8085/shipments/" `
    -Method Post `
    -ContentType "application/json" `
    -Body $shipmentBody
```

---

## Troubleshooting

### Service Won't Start

**Check Logs:**
```powershell
docker logs <service-name>
```

**Common Issues:**
1. **Port Already in Use:** Another application is using the port
   - Solution: Stop the conflicting application or change port in docker-compose.yml

2. **Database Connection Failed:** Database not ready
   - Solution: Wait 10-15 seconds for database initialization
   - Or restart: `docker-compose restart <service-name>`

3. **Environment Variables Missing:** Check .env files
   - Solution: Verify .env file exists in service directory

### Database Issues

**Reset Database:**
```powershell
# Remove specific database volume
docker-compose down -v <database-service-name>

# Recreate
docker-compose up -d <database-service-name>

# Wait and start dependent service
Start-Sleep -Seconds 10
docker-compose up -d <app-service-name>
```

### E2E Test Fails

1. **Check all services are healthy:** `docker-compose ps`
2. **Verify databases are seeded:** Run seed commands again
3. **Check logs for errors:** `docker logs <service-name>`
4. **Restart services:** `docker-compose restart`
5. **Clean restart:** `docker-compose down && docker-compose up -d`

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Client / E2E Test                     │
└────────┬──────────┬──────────┬──────────┬──────────┬────────┘
         │          │          │          │          │
    ┌────▼────┐┌───▼────┐┌───▼────┐┌────▼────┐┌───▼─────┐
    │ Catalog ││Inventory││  Order  ││ Payment ││Shipping │
    │ :8090   ││  :8081  ││  :8082  ││  :8086  ││  :8085  │
    │ Node.js ││ Node.js ││ Python  ││ Python  ││ Python  │
    └────┬────┘└────┬────┘└────┬────┘└────┬────┘└────┬─────┘
         │          │          │          │          │
    ┌────▼────┐┌───▼────┐┌───▼────┐┌────▼────┐┌───▼─────┐
    │  MySQL  ││ MySQL  ││ MySQL  ││Postgres ││Postgres │
    │  8.4    ││  8.0   ││  8.0   ││   14    ││   14    │
    └─────────┘└────────┘└────────┘└─────────┘└─────────┘
```

**Database-Per-Service Pattern:** Each microservice maintains its own database

---

## Service Details

### Catalog Service (Node.js)
- **Port:** 8090
- **Database:** MySQL 8.4
- **Purpose:** Product catalog management
- **Seed Data:** 10 products

### Inventory Service (Node.js)
- **Port:** 8081
- **Database:** MySQL 8.0
- **Purpose:** Inventory tracking and reservation
- **Seed Data:** 6 warehouse records

### Order Service (Python/FastAPI)
- **Port:** 8082
- **Database:** MySQL 8.0
- **Purpose:** Order orchestration and workflow
- **Coordinates:** Catalog, Inventory, Payment, Shipping services

### Payment Service (Python/FastAPI)
- **Port:** 8086
- **Database:** PostgreSQL 14
- **Purpose:** Payment processing with idempotency
- **Features:** Multiple payment methods, transaction logging

### Shipping Service (Python/FastAPI)
- **Port:** 8085
- **Database:** PostgreSQL 14
- **Purpose:** Shipment creation and tracking
- **Features:** Status updates, tracking numbers

---

## Production Considerations

### Security
- [ ] Add API authentication (JWT tokens)
- [ ] Implement rate limiting
- [ ] Use secrets management (not .env files)
- [ ] Enable HTTPS/TLS

### Monitoring
- [ ] Add centralized logging (ELK stack)
- [ ] Implement metrics collection (Prometheus)
- [ ] Set up alerting (Grafana)
- [ ] Add distributed tracing (Jaeger)

### Scalability
- [ ] Deploy to Kubernetes
- [ ] Implement horizontal pod autoscaling
- [ ] Add load balancer
- [ ] Configure resource limits

### Reliability
- [ ] Implement circuit breakers
- [ ] Add retry mechanisms with exponential backoff
- [ ] Set up backup and disaster recovery
- [ ] Configure health checks and liveness probes

---

## Support

For issues or questions:
1. Check service logs: `docker logs <service-name>`
2. Review E2E test output: `.\test-5-services-e2e.ps1`
3. Verify configuration: Check `docker-compose.yml` and `.env` files
4. Clean restart: `docker-compose down -v && docker-compose up -d`

---

**Last Updated:** November 8, 2025  
**Version:** 1.0  
**Status:** Production Ready ✅
