# Deployment Guide for ECI Platform

## Overview

This guide covers deployment of all 6 microservices in the ECI platform using Docker Compose (local) and Kubernetes (production-like).

## Prerequisites

### Required Software
- **Docker**: v20.10 or higher
- **Docker Compose**: v2.0 or higher
- **Minikube**: v1.30 or higher (for Kubernetes)
- **kubectl**: v1.27 or higher (for Kubernetes)
- **Git**: Latest version

### System Requirements
- **RAM**: Minimum 8GB (16GB recommended)
- **CPU**: Minimum 4 cores
- **Disk Space**: 20GB free space

## Architecture

### Service Ports
| Service | Local Port | Container Port | Database Port |
|---------|-----------|----------------|---------------|
| Catalog | 8001 | 8000 | - |
| Order | 8002 | 8000 | - |
| Inventory | 8003 | 8000 | - |
| Notification | 8004 | 8000 | - |
| Shipping | 8085 | 8000 | 5433 |
| Payment | 8086 | 8000 | 5434 |

### Service Dependencies
```
Order Service
├── Catalog Service
├── Inventory Service
├── Payment Service
├── Shipping Service
└── Notification Service

Payment Service
├── Order Service
├── Inventory Service
└── Notification Service

Shipping Service
├── Order Service
├── Inventory Service
└── Notification Service
```

## Option 1: Docker Compose Deployment

### Step 1: Clone All Repositories

```powershell
# Create workspace directory
mkdir C:\eci-services
cd C:\eci-services

# Clone all service repositories
git clone https://github.com/YourOrg/eci-catalog-service.git
git clone https://github.com/YourOrg/eci-order-service.git
git clone https://github.com/YourOrg/eci-inventory-service.git
git clone https://github.com/YourOrg/eci-notification-service.git
git clone https://github.com/Infantselva015/eci-shipping-service.git
git clone https://github.com/Infantselva015/eci-payment-service.git

# Clone integration repository
git clone https://github.com/YourOrg/eci-platform-integration.git
```

### Step 2: Verify Directory Structure

```
C:\eci-services\
├── eci-catalog-service/
├── eci-order-service/
├── eci-inventory-service/
├── eci-notification-service/
├── eci-shipping-service/
├── eci-payment-service/
└── eci-platform-integration/
```

### Step 3: Start All Services

```powershell
cd eci-platform-integration

# Start all services in detached mode
docker-compose up -d

# Watch the logs
docker-compose logs -f
```

### Step 4: Verify Deployment

```powershell
# Check all containers are running
docker-compose ps

# Run health check
.\scripts\health-check-all.ps1

# Access Swagger UI for each service
start http://localhost:8001/docs  # Catalog
start http://localhost:8002/docs  # Order
start http://localhost:8003/docs  # Inventory
start http://localhost:8004/docs  # Notification
start http://localhost:8085/docs  # Shipping
start http://localhost:8086/docs  # Payment
```

### Step 5: Test End-to-End Workflow

```powershell
# Run E2E test
.\tests\test-e2e-workflow.ps1
```

### Step 6: View Logs

```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f payment-service
docker-compose logs -f shipping-service
```

### Step 7: Stop Services

```powershell
# Stop all services
docker-compose down

# Stop and remove volumes (clean state)
docker-compose down -v
```

## Option 2: Kubernetes Deployment (Minikube)

### Step 1: Start Minikube

```powershell
# Start Minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --driver=hyperv

# Verify Minikube is running
minikube status
```

### Step 2: Configure Docker to Use Minikube

```powershell
# Point Docker to Minikube's daemon
& minikube docker-env --shell powershell | Invoke-Expression

# Verify connection
docker ps
```

### Step 3: Build Docker Images

```powershell
cd C:\eci-services

# Build Catalog Service
cd eci-catalog-service
docker build -t eci-catalog-service:latest .

# Build Order Service
cd ..\eci-order-service
docker build -t eci-order-service:latest .

# Build Inventory Service
cd ..\eci-inventory-service
docker build -t eci-inventory-service:latest .

# Build Notification Service
cd ..\eci-notification-service
docker build -t eci-notification-service:latest .

# Build Shipping Service
cd ..\eci-shipping-service
docker build -t eci-shipping-service:latest .

# Build Payment Service
cd ..\eci-payment-service
docker build -t eci-payment-service:latest .
```

### Step 4: Deploy to Kubernetes

```powershell
cd ..\eci-platform-integration

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy each service (if individual k8s folders exist in service repos)
kubectl apply -f ..\eci-catalog-service\k8s\
kubectl apply -f ..\eci-order-service\k8s\
kubectl apply -f ..\eci-inventory-service\k8s\
kubectl apply -f ..\eci-notification-service\k8s\
kubectl apply -f ..\eci-shipping-service\k8s\
kubectl apply -f ..\eci-payment-service\k8s\
```

### Step 5: Verify Deployment

```powershell
# Check namespace
kubectl get namespaces

# Check all pods
kubectl get pods -n eci-platform

# Check services
kubectl get services -n eci-platform

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n eci-platform --timeout=300s
```

### Step 6: Access Services

```powershell
# Port forward each service (open separate terminals)

# Terminal 1 - Catalog
kubectl port-forward -n eci-platform svc/catalog-service 8001:80

# Terminal 2 - Order
kubectl port-forward -n eci-platform svc/order-service 8002:80

# Terminal 3 - Inventory
kubectl port-forward -n eci-platform svc/inventory-service 8003:80

# Terminal 4 - Notification
kubectl port-forward -n eci-platform svc/notification-service 8004:80

# Terminal 5 - Shipping
kubectl port-forward -n eci-platform svc/shipping-service 8085:80

# Terminal 6 - Payment
kubectl port-forward -n eci-platform svc/payment-service 8086:80
```

### Step 7: Test in Kubernetes

```powershell
# Run E2E test
.\tests\test-e2e-workflow.ps1
```

### Step 8: View Logs

```powershell
# View logs for a specific pod
kubectl logs -n eci-platform -l app=payment-service -f

# View logs for all pods
kubectl logs -n eci-platform --all-containers=true -f
```

### Step 9: Cleanup

```powershell
# Delete all resources
kubectl delete namespace eci-platform

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

## Troubleshooting

### Issue: Ports Already in Use

```powershell
# Find process using port
netstat -ano | findstr "8001"

# Kill process
taskkill /PID <PID> /F
```

### Issue: Docker Build Fails

```powershell
# Clean Docker cache
docker system prune -a

# Rebuild with no cache
docker build --no-cache -t service-name:latest .
```

### Issue: Services Can't Communicate

**Docker Compose:**
- Verify all services are on the same network: `docker network ls`
- Check service names match in environment variables

**Kubernetes:**
- Verify services are in the same namespace
- Check service DNS: `kubectl exec -it <pod> -n eci-platform -- nslookup payment-service`

### Issue: Database Connection Errors

```powershell
# Check database is running
docker ps | findstr postgres

# Connect to database manually
docker exec -it payment-postgres psql -U payment_user -d payment_db

# Verify connection string in env vars
docker inspect payment-service | findstr DATABASE_URL
```

### Issue: Minikube Won't Start

```powershell
# Delete and recreate
minikube delete
minikube start --cpus=4 --memory=8192 --driver=hyperv

# Check system resources
minikube status
```

## Performance Optimization

### Docker Compose
- Use multi-stage builds in Dockerfiles
- Enable BuildKit: `$env:DOCKER_BUILDKIT=1`
- Limit container resources in docker-compose.yml

### Kubernetes
- Set resource limits/requests in deployment manifests
- Use horizontal pod autoscaling
- Configure liveness and readiness probes

## Security Best Practices

1. **Secrets Management**
   - Use Kubernetes Secrets for sensitive data
   - Never commit passwords to git
   - Rotate credentials regularly

2. **Network Security**
   - Use network policies in Kubernetes
   - Limit exposed ports
   - Use HTTPS in production

3. **Image Security**
   - Scan images for vulnerabilities
   - Use minimal base images (alpine)
   - Don't run as root user

## Monitoring

### Docker Compose
```powershell
# View container stats
docker stats

# View specific metrics
docker stats payment-service shipping-service
```

### Kubernetes
```powershell
# View pod resource usage
kubectl top pods -n eci-platform

# View node resource usage
kubectl top nodes
```

## Next Steps

1. Configure CI/CD pipeline
2. Set up monitoring with Prometheus/Grafana
3. Configure centralized logging (ELK stack)
4. Implement API gateway
5. Add distributed tracing (Jaeger/Zipkin)
