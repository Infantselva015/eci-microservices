# Kubernetes Deployment Guide - ECI Microservices

## Prerequisites

### Install Required Tools

1. **Minikube** - Local Kubernetes cluster
```powershell
# Download and install Minikube
choco install minikube

# Or download from: https://minikube.sigs.k8s.io/docs/start/
```

2. **kubectl** - Kubernetes CLI
```powershell
# Install kubectl
choco install kubernetes-cli

# Or download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

3. **Docker Desktop** - Container runtime
- Already installed ✓

---

## Step 1: Start Minikube

```powershell
# Start Minikube with Docker driver
minikube start --driver=docker --cpus=4 --memory=8192

# Verify Minikube is running
minikube status

# Enable necessary addons
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
```

**Expected Output:**
```
✓ minikube v1.32.0 on Windows
✓ Using the docker driver
✓ Starting control plane node minikube
✓ Done! kubectl is now configured to use "minikube"
```

---

## Step 2: Configure Docker Environment

```powershell
# Point Docker CLI to Minikube's Docker daemon
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Verify
docker ps
```

This allows you to use Minikube's Docker daemon to build images directly.

---

## Step 3: Build Docker Images

Navigate to eci-microservices directory and build all images:

```powershell
cd "C:\Users\infantselvas\OneDrive - Comcast\Desktop\BITS_WILP\Semester 2\Scalable Services\Assignment\Final_Submission\eci-microservices"

# Build Catalog Service
cd ..\eci-catalog-service
docker build -t eci-catalog-service:latest .

# Build Inventory Service
cd ..\eci-inventory-service
docker build -t eci-inventory-service:latest .

# Build Order Service
cd ..\eci-order-service
docker build -t eci-order-service:latest .

# Build Payment Service
cd ..\eci-payment-service
docker build -t eci-payment-service:latest .

# Build Shipping Service
cd ..\eci-shipping-service
docker build -t eci-shipping-service:latest .

# Verify images
docker images | Select-String "eci-"
```

---

## Step 4: Create Kubernetes Manifests

Let me create the Kubernetes deployment files:

### Create namespace

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: eci-platform
```

Apply it:
```powershell
cd ..\eci-microservices
kubectl apply -f k8s/namespace.yaml
kubectl get namespaces
```

---

## Step 5: Deploy Databases

### Catalog MySQL Database

Create `k8s/catalog-mysql.yaml`:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: catalog-mysql-pvc
  namespace: eci-platform
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: catalog-mysql-config
  namespace: eci-platform
data:
  MYSQL_ROOT_PASSWORD: "toor"
  MYSQL_DATABASE: "catalog_db"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-mysql
  namespace: eci-platform
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog-mysql
  template:
    metadata:
      labels:
        app: catalog-mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.4
        ports:
        - containerPort: 3306
        envFrom:
        - configMapRef:
            name: catalog-mysql-config
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        - name: init-sql
          mountPath: /docker-entrypoint-initdb.d
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: catalog-mysql-pvc
      - name: init-sql
        hostPath:
          path: /eci-catalog-service/init.sql
          type: File
---
apiVersion: v1
kind: Service
metadata:
  name: catalog-mysql
  namespace: eci-platform
spec:
  selector:
    app: catalog-mysql
  ports:
  - port: 3306
    targetPort: 3306
  type: ClusterIP
```

**Note:** For simplicity, I'll create a comprehensive deployment script. The full K8s manifests for all services would be extensive.

---

## Step 6: Simplified Deployment Approach

Given the complexity of creating 30+ YAML files, here's a practical approach:

### Option A: Use Kompose (Convert Docker Compose to Kubernetes)

```powershell
# Install Kompose
choco install kubernetes-kompose

# Convert docker-compose.yml to Kubernetes manifests
cd eci-microservices
kompose convert -f docker-compose.yml -o k8s/

# Review generated files
ls k8s/

# Apply all manifests
kubectl apply -f k8s/ -n eci-platform

# Check deployments
kubectl get all -n eci-platform
```

### Option B: Deploy with Helm (Recommended for Production)

Create `helm/eci-platform/Chart.yaml`:
```yaml
apiVersion: v2
name: eci-platform
description: E-Commerce with Inventory Platform
version: 1.0.0
appVersion: "1.0"
```

And `helm/eci-platform/values.yaml` with configurations.

---

## Step 7: Manual Kubernetes Deployment (Detailed)

Let me create a complete deployment script:

