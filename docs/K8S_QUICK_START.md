# Kubernetes Deployment - Complete Guide

## Quick Start (Using Kompose)

The fastest way to deploy to Kubernetes is using Kompose to convert docker-compose.yml:

### Step 1: Install Tools

```powershell
# Install Minikube
choco install minikube

# Install kubectl
choco install kubernetes-cli

# Install Kompose
choco install kubernetes-kompose
```

### Step 2: Start Minikube

```powershell
# Start Minikube
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g

# Verify
minikube status
kubectl cluster-info
```

### Step 3: Point Docker to Minikube

```powershell
# Configure Docker to use Minikube's daemon
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
```

### Step 4: Build Images in Minikube

```powershell
cd "Final_Submission\eci-microservices"

# Build all service images
docker-compose build

# Verify images are in Minikube
docker images | Select-String "eci-"
```

### Step 5: Convert Docker Compose to Kubernetes

```powershell
# Create k8s directory if not exists
New-Item -ItemType Directory -Force -Path k8s-generated

# Convert docker-compose.yml to Kubernetes manifests
kompose convert -f docker-compose.yml -o k8s-generated/

# Review generated files
Get-ChildItem k8s-generated/
```

**Files Generated:**
- `catalog-mysql-deployment.yaml`
- `catalog-mysql-service.yaml`
- `catalog-mysql-claim0-persistentvolumeclaim.yaml`
- `catalog-service-deployment.yaml`
- `catalog-service-service.yaml`
- (Similar files for other 4 services and databases)

### Step 6: Update Image Pull Policy

```powershell
# Update all deployment files to use local images
Get-ChildItem k8s-generated/*-deployment.yaml | ForEach-Object {
    (Get-Content $_) -replace 'imagePullPolicy: ""', 'imagePullPolicy: Never' | Set-Content $_
}
```

### Step 7: Create Namespace

```powershell
kubectl create namespace eci-platform

# Or apply the existing namespace.yaml
kubectl apply -f k8s/namespace.yaml
```

### Step 8: Deploy to Kubernetes

```powershell
# Apply all manifests
kubectl apply -f k8s-generated/ -n eci-platform

# Watch deployment progress
kubectl get pods -n eci-platform -w
```

### Step 9: Verify Deployment

```powershell
# Check all resources
kubectl get all -n eci-platform

# Check pods status
kubectl get pods -n eci-platform

# Check services
kubectl get svc -n eci-platform

# Check persistent volumes
kubectl get pvc -n eci-platform
```

**Expected Output:**
```
NAME                                   READY   STATUS    RESTARTS   AGE
pod/catalog-mysql-xxx                  1/1     Running   0          2m
pod/catalog-service-xxx                1/1     Running   0          2m
pod/inventory-mysql-xxx                1/1     Running   0          2m
pod/inventory-service-xxx              1/1     Running   0          2m
pod/order-mysql-xxx                    1/1     Running   0          2m
pod/order-service-xxx                  1/1     Running   0          2m
pod/payment-postgres-xxx               1/1     Running   0          2m
pod/payment-service-xxx                1/1     Running   0          2m
pod/shipping-postgres-xxx              1/1     Running   0          2m
pod/shipping-service-xxx               1/1     Running   0          2m
```

### Step 10: Expose Services

```powershell
# Port forward to access services locally
# Catalog Service
kubectl port-forward -n eci-platform svc/catalog-service 8090:8090

# In separate terminals, forward other services:
kubectl port-forward -n eci-platform svc/inventory-service 8081:8081
kubectl port-forward -n eci-platform svc/order-service 8082:8082
kubectl port-forward -n eci-platform svc/payment-service 8086:8086
kubectl port-forward -n eci-platform svc/shipping-service 8085:8085
```

### Step 11: Test Services

```powershell
# Test health endpoints
Invoke-RestMethod http://localhost:8090/health
Invoke-RestMethod http://localhost:8081/health
Invoke-RestMethod http://localhost:8082/health
Invoke-RestMethod http://localhost:8086/health
Invoke-RestMethod http://localhost:8085/health
```

### Step 12: Seed Databases

```powershell
# Get pod names
$catalogPod = kubectl get pods -n eci-platform -l app=catalog-service -o jsonpath='{.items[0].metadata.name}'
$inventoryPod = kubectl get pods -n eci-platform -l app=inventory-service -o jsonpath='{.items[0].metadata.name}'

# Seed catalog
kubectl exec -n eci-platform $catalogPod -- npm run seed

# Seed inventory
kubectl exec -n eci-platform $inventoryPod -- npm run seed
```

---

## Alternative: Using NodePort Services

If you want direct access without port-forwarding:

```powershell
# Patch services to use NodePort
kubectl patch svc catalog-service -n eci-platform -p '{"spec": {"type": "NodePort"}}'
kubectl patch svc inventory-service -n eci-platform -p '{"spec": {"type": "NodePort"}}'
kubectl patch svc order-service -n eci-platform -p '{"spec": {"type": "NodePort"}}'
kubectl patch svc payment-service -n eci-platform -p '{"spec": {"type": "NodePort"}}'
kubectl patch svc shipping-service -n eci-platform -p '{"spec": {"type": "NodePort"}}'

# Get NodePort URLs
minikube service catalog-service -n eci-platform --url
minikube service inventory-service -n eci-platform --url
minikube service order-service -n eci-platform --url
minikube service payment-service -n eci-platform --url
minikube service shipping-service -n eci-platform --url
```

---

## Monitoring and Debugging

### View Logs

```powershell
# Get pod names
kubectl get pods -n eci-platform

# View logs for specific pod
kubectl logs -n eci-platform <pod-name>

# Follow logs
kubectl logs -n eci-platform <pod-name> -f

# View logs for all containers in a pod
kubectl logs -n eci-platform <pod-name> --all-containers=true
```

### Access Pod Shell

```powershell
# Access catalog service pod
kubectl exec -it -n eci-platform <catalog-pod-name> -- /bin/sh

# Access database pod
kubectl exec -it -n eci-platform <mysql-pod-name> -- mysql -ptoor
```

### Check Resource Usage

```powershell
# View resource usage
kubectl top pods -n eci-platform
kubectl top nodes

# Describe pod for detailed info
kubectl describe pod -n eci-platform <pod-name>
```

### View Events

```powershell
# View namespace events
kubectl get events -n eci-platform --sort-by='.lastTimestamp'
```

---

## Scaling Services

```powershell
# Scale catalog service to 3 replicas
kubectl scale deployment catalog-service -n eci-platform --replicas=3

# Verify scaling
kubectl get pods -n eci-platform -l app=catalog-service

# Auto-scale based on CPU
kubectl autoscale deployment catalog-service -n eci-platform --cpu-percent=80 --min=2 --max=5
```

---

## Configuration Management

### Using ConfigMaps

```powershell
# Create ConfigMap from .env file
kubectl create configmap order-config -n eci-platform --from-env-file=../eci-order-service/.env

# View ConfigMap
kubectl get configmap -n eci-platform
kubectl describe configmap order-config -n eci-platform
```

### Using Secrets

```powershell
# Create secret for database passwords
kubectl create secret generic db-passwords -n eci-platform \
  --from-literal=mysql-root-password=toor \
  --from-literal=postgres-password=postgres

# View secrets (values are base64 encoded)
kubectl get secrets -n eci-platform
```

---

## Cleanup

```powershell
# Delete all resources in namespace
kubectl delete namespace eci-platform

# Or delete specific resources
kubectl delete -f k8s-generated/ -n eci-platform

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

---

## Troubleshooting

### Pod Not Starting

```powershell
# Check pod status
kubectl describe pod -n eci-platform <pod-name>

# Common issues:
# - ImagePullBackOff: Image not found or pull policy wrong
#   Fix: Set imagePullPolicy: Never for local images
# - CrashLoopBackOff: Container keeps crashing
#   Fix: Check logs with kubectl logs
# - Pending: Insufficient resources
#   Fix: Increase Minikube resources or scale down
```

### Database Connection Issues

```powershell
# Check if database pod is running
kubectl get pods -n eci-platform | Select-String "mysql|postgres"

# Test database connection from service pod
kubectl exec -n eci-platform <service-pod> -- ping catalog-mysql
```

### Port Conflicts

```powershell
# If port-forward fails, use different local port
kubectl port-forward -n eci-platform svc/catalog-service 9090:8090
```

---

## Dashboard Access

```powershell
# Open Kubernetes Dashboard
minikube dashboard

# Or manually:
kubectl proxy
# Then open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## Production Considerations

### 1. Use Ingress Controller

```powershell
# Enable ingress
minikube addons enable ingress

# Create Ingress resource
# See k8s/ingress.yaml for configuration
```

### 2. Resource Limits

Add to deployment specs:
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 3. Health Checks

Add liveness and readiness probes:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8090
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /health
    port: 8090
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 4. Persistent Storage

Use proper StorageClass for production:
```yaml
storageClassName: standard  # or ssd, fast, etc.
```

---

## Quick Reference

```powershell
# Start Minikube
minikube start --driver=docker --cpus=4 --memory=8192

# Point Docker to Minikube
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Build images
docker-compose build

# Convert to Kubernetes
kompose convert -f docker-compose.yml -o k8s-generated/

# Deploy
kubectl apply -f k8s-generated/ -n eci-platform

# Check status
kubectl get all -n eci-platform

# Port forward services
kubectl port-forward -n eci-platform svc/catalog-service 8090:8090

# View logs
kubectl logs -n eci-platform <pod-name>

# Cleanup
kubectl delete namespace eci-platform
```

---

## Expected Timeline

- **Setup (Minikube + Tools):** 15-20 minutes
- **Build Images:** 5-10 minutes
- **Deploy to K8s:** 5-10 minutes
- **Testing:** 10-15 minutes
- **Total:** ~45-60 minutes

---

## Success Criteria

✅ All 10 pods running (5 services + 5 databases)  
✅ All services accessible via port-forward or NodePort  
✅ Health checks passing  
✅ Inter-service communication working  
✅ Databases seeded with data  
✅ E2E workflow functional  

---

**Note:** This is a development/testing deployment. For production, consider:
- Helm charts for easier management
- Proper secrets management (Vault, Sealed Secrets)
- Monitoring (Prometheus, Grafana)
- Logging (EFK/ELK stack)
- Service mesh (Istio, Linkerd)
- CI/CD integration (ArgoCD, Flux)
