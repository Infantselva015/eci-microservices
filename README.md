# ECI Platform - Integration Repository

This repository contains the integration layer for the E-Commerce with Inventory (ECI) microservices platform.

## 🏗️ Architecture Overview

The ECI platform consists of 6 independent microservices:

1. **Catalog Service** (Port 8001) - Product catalog management
2. **Order Service** (Port 8002) - Order processing
3. **Inventory Service** (Port 8003) - Stock management
4. **Notification Service** (Port 8004) - Email/SMS notifications
5. **Shipping Service** (Port 8085) - Shipment tracking & delivery
6. **Payment Service** (Port 8086) - Payment processing & refunds

## 📦 Service Repositories

Each service has its own independent repository:

```
├── eci-catalog-service       (https://github.com/YourOrg/eci-catalog-service)
├── eci-order-service         (https://github.com/YourOrg/eci-order-service)
├── eci-inventory-service     (https://github.com/YourOrg/eci-inventory-service)
├── eci-notification-service  (https://github.com/YourOrg/eci-notification-service)
├── eci-shipping-service      (https://github.com/Infantselva015/eci-shipping-service)
└── eci-payment-service       (https://github.com/Infantselva015/eci-payment-service)
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Minikube (for Kubernetes deployment)
- kubectl CLI
- Git

### Option 1: Docker Compose Deployment (Recommended for Local Testing)

1. **Clone all service repositories:**
```bash
# Create a workspace directory
mkdir eci-services
cd eci-services

# Clone all service repos
git clone https://github.com/YourOrg/eci-catalog-service.git
git clone https://github.com/YourOrg/eci-order-service.git
git clone https://github.com/YourOrg/eci-inventory-service.git
git clone https://github.com/YourOrg/eci-notification-service.git
git clone https://github.com/Infantselva015/eci-shipping-service.git
git clone https://github.com/Infantselva015/eci-payment-service.git

# Clone this integration repo
git clone https://github.com/YourOrg/eci-platform-integration.git
```

2. **Start all services:**
```bash
cd eci-platform-integration
docker-compose up -d
```

3. **Verify all services are running:**
```bash
docker-compose ps
```

4. **Access service endpoints:**
- Catalog: http://localhost:8001/docs
- Order: http://localhost:8002/docs
- Inventory: http://localhost:8003/docs
- Notification: http://localhost:8004/docs
- Shipping: http://localhost:8085/docs
- Payment: http://localhost:8086/docs

### Option 2: Kubernetes Deployment (Production-like)

1. **Start Minikube:**
```bash
minikube start --cpus=4 --memory=8192
```

2. **Build Docker images in Minikube context:**
```bash
# Point Docker to Minikube's daemon
eval $(minikube docker-env)

# Build all service images
cd ../eci-catalog-service && docker build -t eci-catalog-service:latest .
cd ../eci-order-service && docker build -t eci-order-service:latest .
cd ../eci-inventory-service && docker build -t eci-inventory-service:latest .
cd ../eci-notification-service && docker build -t eci-notification-service:latest .
cd ../eci-shipping-service && docker build -t eci-shipping-service:latest .
cd ../eci-payment-service && docker build -t eci-payment-service:latest .
```

3. **Deploy to Kubernetes:**
```bash
cd ../eci-platform-integration

# Apply all Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n eci-platform --timeout=300s
```

4. **Access services via port-forwarding:**
```bash
kubectl port-forward -n eci-platform svc/catalog-service 8001:80
kubectl port-forward -n eci-platform svc/order-service 8002:80
kubectl port-forward -n eci-platform svc/inventory-service 8003:80
kubectl port-forward -n eci-platform svc/notification-service 8004:80
kubectl port-forward -n eci-platform svc/shipping-service 8085:80
kubectl port-forward -n eci-platform svc/payment-service 8086:80
```

## 🧪 Testing

### End-to-End Workflow Test

Run the complete order flow test:
```bash
cd tests
./test-e2e-workflow.sh
```

This will test:
1. Browse products (Catalog)
2. Reserve inventory (Inventory)
3. Create order (Order)
4. Charge payment (Payment)
5. Create shipment (Shipping)
6. Track delivery (Shipping)
7. Send notifications (Notification)

### Individual Service Tests

```bash
# Test Catalog Service
curl http://localhost:8001/v1/products

# Test Order Service
curl http://localhost:8002/v1/orders

# Test Inventory Service
curl http://localhost:8003/v1/inventory

# Test Notification Service
curl http://localhost:8004/health

# Test Shipping Service
curl http://localhost:8085/health

# Test Payment Service
curl http://localhost:8086/health
```

## 📊 Monitoring

### Health Checks
```bash
# Check all service health
./scripts/health-check-all.sh
```

### Metrics
```bash
# View Prometheus metrics for each service
curl http://localhost:8001/metrics
curl http://localhost:8002/metrics
curl http://localhost:8003/metrics
curl http://localhost:8004/metrics
curl http://localhost:8085/metrics
curl http://localhost:8086/metrics
```

### Logs

**Docker Compose:**
```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f payment-service
docker-compose logs -f shipping-service
```

**Kubernetes:**
```bash
# View all pods
kubectl get pods -n eci-platform

# View specific service logs
kubectl logs -n eci-platform -l app=payment-service -f
kubectl logs -n eci-platform -l app=shipping-service -f
```

## 🗄️ Database Access

Each service has its own database (database-per-service pattern):

```bash
# Payment DB (PostgreSQL)
docker exec -it payment-postgres psql -U payment_user -d payment_db

# Shipping DB (PostgreSQL)
docker exec -it shipping-postgres psql -U shipping_user -d shipping_db

# Order DB (PostgreSQL)
docker exec -it order-postgres psql -U order_user -d order_db

# Inventory DB (PostgreSQL)
docker exec -it inventory-postgres psql -U inventory_user -d inventory_db

# Catalog DB (PostgreSQL)
docker exec -it catalog-postgres psql -U catalog_user -d catalog_db
```

## 🔧 Troubleshooting

### Services won't start
```bash
# Clean up and restart
docker-compose down -v
docker-compose up -d
```

### Port conflicts
Check if ports are already in use:
```bash
netstat -an | findstr "8001 8002 8003 8004 8085 8086"
```

### Database connection issues
```bash
# Restart databases
docker-compose restart payment-postgres shipping-postgres order-postgres inventory-postgres catalog-postgres
```

## 📖 Documentation

- [API Documentation](./docs/API.md)
- [Deployment Guide](./docs/DEPLOYMENT.md)
- [Architecture Decisions](./docs/ARCHITECTURE.md)
- [Troubleshooting Guide](./docs/TROUBLESHOOTING.md)

## 👥 Team Members

- Member 1: Catalog Service & Notification Service
- Member 2: Order Service & Inventory Service
- Member 3: Payment Service & Shipping Service (Infantselva)

## 📝 License

This project is part of BITS WILP Scalable Services Assignment.

## 🎯 Assignment Submission

**Deadline:** November 10, 2025

**Deliverables:**
1. All 6 service repositories (individual repos)
2. Integration repository (this repo)
3. Demo video (max 15 minutes)
4. Documentation PDF with screenshots
5. Google Drive submission: `<GroupNumber>_ECI_Platform.zip`

**Submission Link:**
https://drive.google.com/drive/folders/1SjEkk9emLeECZBSqHuCfRZORI6378rM4
