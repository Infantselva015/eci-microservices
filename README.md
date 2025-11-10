# ECI Microservices Platform

A comprehensive e-commerce microservices platform built with Node.js, Python FastAPI, MySQL, PostgreSQL, Docker, and Kubernetes.

## Project Overview

This project demonstrates a production-ready microservices architecture with 5 independent services handling catalog management, inventory tracking, order processing, payment processing, and shipping logistics. The platform showcases modern cloud-native development practices including containerization, orchestration, service mesh communication, and automated deployment pipelines.

## Architecture

### Microservices

1. **Catalog Service** (Node.js + MySQL 8.4)
   - Product catalog management
   - Category organization
   - Product search and filtering
   - Port: 8080 (Local: 9090)

2. **Inventory Service** (Node.js + MySQL 8.0)
   - Multi-warehouse inventory tracking
   - Stock level monitoring
   - Low stock alerts
   - Port: 8081 (Local: 9091)

3. **Order Service** (Python FastAPI + MySQL 8.0)
   - Order creation and management
   - Order status tracking
   - Customer order history
   - Port: 8000 (Local: 9082)

4. **Payment Service** (Python FastAPI + PostgreSQL 14)
   - Payment processing
   - Transaction management
   - Refund handling
   - Idempotency support
   - Port: 8006 (Local: 9086)

5. **Shipping Service** (Python FastAPI + PostgreSQL 14)
   - Shipment creation and tracking
   - Carrier integration
   - Delivery status updates
   - Port: 8005 (Local: 9085)

### Technology Stack

- **Backend Frameworks**: Node.js (Express), Python (FastAPI)
- **Databases**: MySQL 8.x, PostgreSQL 14
- **Containerization**: Docker
- **Orchestration**: Kubernetes (Minikube)
- **Service Communication**: REST APIs
- **Monitoring**: Kubernetes Dashboard

## Project Structure

```
eci-microservices/
├── docs/
│   └── DEPLOYMENT.md              # Detailed deployment guide
├── k8s/
│   ├── namespace.yaml             # Kubernetes namespace definition
│   └── deploy-all-services.yaml  # Complete K8s deployment manifest (702 lines)
├── scripts/
│   ├── cleanup-all.ps1            # Complete cleanup script
│   ├── deploy-complete.ps1        # Master deployment automation
│   ├── health-check-all.ps1      # Health check for all services
│   ├── health-check.ps1           # Individual service health check
│   ├── seed-300-products.ps1      # Product data seeding script
│   ├── seed-300-products.sql      # Product seed data (300 products)
│   ├── seed-inventory.ps1         # Inventory data seeding script
│   ├── seed-inventory.sql         # Inventory seed data (66 records)
│   ├── test-all-services-k8s.ps1 # E2E test suite (11 tests)
│   ├── test-order-workflow-k8s.ps1# Order workflow testing
│   ├── test-place-order.ps1       # Sample order placement
│   └── README.md                  # Scripts documentation
├── docker-compose.yml             # Docker Compose configuration
├── K8S_DASHBOARD_GUIDE.md         # Kubernetes Dashboard usage guide
├── VIDEO_DEMO_GUIDE.md            # Video demonstration script
└── README.md                      # This file
```

### Individual Service Repositories

Each microservice maintains its own repository with complete source code:

- **eci-catalog-service/** - Product catalog microservice
- **eci-inventory-service/** - Inventory management microservice  
- **eci-order-service/** - Order processing microservice
- **eci-payment-service/** - Payment processing microservice
- **eci-shipping-service/** - Shipping logistics microservice

## Quick Start

### Prerequisites

- Docker Desktop (with Kubernetes enabled)
- Minikube v1.37.0+
- kubectl v1.32.0+
- PowerShell 5.1+
- 8GB+ RAM available

### One-Command Deployment

```powershell
# Navigate to scripts directory
cd eci-microservices\scripts

# Run complete deployment
.\deploy-complete.ps1
```

This automated script will:
1. Build all 5 Docker images
2. Load images to Minikube
3. Deploy to Kubernetes (namespace: eci)
4. Seed 300 products across multiple categories
5. Seed 66 inventory records in 5 warehouses
6. Place sample orders automatically
7. Run 11 E2E tests to verify deployment
8. Launch Kubernetes Dashboard

**Deployment Time**: ~3-4 minutes

## Sequential Deployment Steps

If you prefer manual step-by-step deployment:

### Step 1: Start Minikube

```powershell
minikube start
minikube status
```

### Step 2: Verify Docker

```powershell
docker ps
```

### Step 3: Build Docker Images

```powershell
# Navigate to parent directory
cd Final_Submission

# Build all services
docker build -t eci-microservices-catalog-service:latest .\eci-catalog-service
docker build -t eci-microservices-inventory-service:latest .\eci-inventory-service
docker build -t eci-microservices-order-service:latest .\eci-order-service
docker build -t eci-microservices-payment-service:latest .\eci-payment-service
docker build -t eci-microservices-shipping-service:latest .\eci-shipping-service
```

### Step 4: Load Images to Minikube

```powershell
minikube image load eci-microservices-catalog-service:latest
minikube image load eci-microservices-inventory-service:latest
minikube image load eci-microservices-order-service:latest
minikube image load eci-microservices-payment-service:latest
minikube image load eci-microservices-shipping-service:latest
```

### Step 5: Deploy to Kubernetes

```powershell
cd eci-microservices
kubectl apply -f k8s/deploy-all-services.yaml
kubectl get pods -n eci --watch
```

### Step 6: Wait for Pods Ready

```powershell
kubectl wait --for=condition=ready pod --all -n eci --timeout=120s
```

### Step 7: Seed Data

```powershell
cd scripts
.\seed-300-products.ps1
.\seed-inventory.ps1
```

### Step 8: Run Tests

```powershell
.\test-all-services-k8s.ps1
```

### Step 9: Launch Dashboard

```powershell
minikube dashboard
```

## Service Access

### Kubernetes NodePort Access

- Catalog Service: `http://localhost:30090`
- Inventory Service: `http://localhost:30091`
- Order Service: `http://localhost:30082`
- Payment Service: `http://localhost:30086`
- Shipping Service: `http://localhost:30085`

### Port-Forward Access

```powershell
kubectl port-forward -n eci svc/catalog-service 9090:8080
kubectl port-forward -n eci svc/inventory-service 9091:8081
kubectl port-forward -n eci svc/order-service 9082:8000
kubectl port-forward -n eci svc/payment-service 9086:8006
kubectl port-forward -n eci svc/shipping-service 9085:8005
```

## Testing

### Health Check All Services

```powershell
cd scripts
.\health-check-all.ps1
```

### Run E2E Tests

```powershell
.\test-all-services-k8s.ps1
```

**Test Coverage**:
- Service health checks (5 tests)
- Database connectivity (5 tests)
- Product retrieval (1 test)
- Inventory check (1 test)
- Order detection (1 test)
- Inter-service communication

### Place Sample Order

```powershell
.\test-place-order.ps1
```

## Monitoring

### Kubernetes Dashboard

```powershell
minikube dashboard
```

Select namespace: **eci**

**Dashboard Features**:
- Pod status and logs
- Service endpoints
- Resource usage (CPU/Memory)
- Persistent volume claims
- ConfigMaps and Secrets
- Event logs

### View Logs

```powershell
# Catalog Service
kubectl logs -n eci -l app=catalog-service --tail=50

# Inventory Service
kubectl logs -n eci -l app=inventory-service --tail=50

# Order Service
kubectl logs -n eci -l app=order-service --tail=50

# Payment Service
kubectl logs -n eci -l app=payment-service --tail=50

# Shipping Service
kubectl logs -n eci -l app=shipping-service --tail=50
```

### Check Pod Status

```powershell
kubectl get pods -n eci
kubectl describe pod <pod-name> -n eci
```

## Data Seeding

### Products (300 items)

- **Electronics**: Laptops, smartphones, tablets, headphones
- **Clothing**: T-shirts, jeans, jackets, shoes
- **Books**: Fiction, non-fiction, textbooks
- **Home & Garden**: Furniture, appliances, decor
- Price range: $9.99 - $1,299.99

### Inventory (66 records)

- **5 Warehouses**: NY, LA, Chicago, Houston, Phoenix
- **Quantity range**: 50-500 units per warehouse
- **Reorder levels**: 10-50 units

## Cleanup

### Complete Cleanup

```powershell
cd scripts
.\cleanup-all.ps1
```

This will:
- Delete Kubernetes namespace 'eci'
- Stop port-forwards
- Remove Docker images
- Clean Minikube cache

### Keep Minikube Running

After cleanup, Minikube continues running. To stop:

```powershell
minikube stop
```

To completely delete:

```powershell
minikube delete
```

## Troubleshooting

### Pods Not Starting

```powershell
# Check pod status
kubectl get pods -n eci

# Check pod events
kubectl describe pod <pod-name> -n eci

# Check logs
kubectl logs <pod-name> -n eci
```

### Service Not Accessible

```powershell
# Verify service endpoints
kubectl get svc -n eci

# Check if pods are ready
kubectl get pods -n eci

# Test internal connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n eci -- sh
```

### Database Connection Issues

```powershell
# Check database pod logs
kubectl logs -n eci <database-pod-name>

# Verify environment variables
kubectl describe pod <service-pod-name> -n eci
```

### Image Pull Errors

```powershell
# List images in Minikube
minikube image ls

# Reload images if missing
minikube image load <image-name>:latest
```

## Performance Considerations

### Resource Limits

Each service has defined resource limits:
- **Memory**: 512Mi-1Gi per service
- **CPU**: 500m-1000m per service
- **Database Storage**: 1Gi per database

### Scaling

```powershell
# Scale catalog service to 3 replicas
kubectl scale deployment catalog-service -n eci --replicas=3

# Verify scaling
kubectl get pods -n eci -l app=catalog-service
```

## Development Workflow

1. **Make code changes** in individual service repositories
2. **Rebuild Docker image** for the modified service
3. **Load image to Minikube**
4. **Restart deployment**:
   ```powershell
   kubectl rollout restart deployment <service-name> -n eci
   ```
5. **Verify changes**:
   ```powershell
   kubectl rollout status deployment <service-name> -n eci
   ```

## API Documentation

### Catalog Service
- `GET /api/products` - List all products
- `GET /api/products/:id` - Get product by ID
- `GET /api/categories` - List categories
- `GET /health` - Health check

### Inventory Service  
- `GET /api/inventory` - List inventory
- `GET /api/inventory/:productId` - Get inventory by product
- `GET /api/warehouses` - List warehouses
- `GET /health` - Health check

### Order Service
- `POST /orders` - Create order
- `GET /orders/:id` - Get order by ID
- `GET /health` - Health check

### Payment Service
- `POST /payments` - Create payment
- `POST /payments/:id/charge` - Charge payment
- `POST /payments/:id/refund` - Refund payment
- `GET /health` - Health check

### Shipping Service
- `POST /shipments` - Create shipment
- `GET /shipments/:id` - Track shipment
- `PUT /shipments/:id/status` - Update status
- `GET /health` - Health check

## CI/CD Integration

This project is designed to integrate with CI/CD pipelines:

1. **Build**: Docker images built on code commit
2. **Test**: Automated E2E tests run
3. **Deploy**: Kubernetes manifests applied
4. **Verify**: Health checks confirm deployment

## Security Considerations

- Database credentials in Kubernetes Secrets
- Service-to-service communication within cluster network
- No root user in container images
- Read-only filesystems where possible
- Resource limits to prevent DoS

## Contributing

Each microservice has its own repository:
- Fork the specific service repository
- Create feature branch
- Make changes and test locally
- Submit pull request

## License

This project is created for educational purposes as part of BITS WILP Scalable Services coursework.

## Support

For issues or questions:
1. Check troubleshooting section
2. Review service logs
3. Verify Kubernetes events
4. Consult individual service README files

## Authors

### Team Members

| Member | Mail-ID | Contribution |
|--------|---------|--------------|
| Anantya Mary J | 2024tm93571@wilp.bits-pilani.ac.in | Inventory & Catalog Services |
| Anoosha R Kolagal | 2024tm93576@wilp.bits-pilani.ac.in | Order Service & Documentation |
| Infantselva S | 2024tm93572@wilp.bits-pilani.ac.in | Payment & Shipping Services |
| Tonpe Neha Rajendra | 2024tm93567@wilp.bits-pilani.ac.in | Notification Service |

- **Program**: BITS WILP - Scalable Services

## Acknowledgments

- BITS WILP Scalable Services Course
- Kubernetes Documentation
- Docker Documentation
- FastAPI Framework
- Express.js Framework

---

**Last Updated**: November 10, 2025
**Version**: 1.0.0
**Status**: Production Ready ✅
