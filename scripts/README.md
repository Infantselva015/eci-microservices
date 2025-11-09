# ECI Platform - Deployment Scripts

## 📁 Scripts Overview

### Main Deployment Scripts

1. **`deploy-complete.ps1`** - Master deployment script
   - Builds all 5 Docker images
   - Deploys to Kubernetes
   - Waits for services to stabilize (45 seconds)
   - Seeds 300 products
   - Runs E2E tests
   - **This is the main script to use!**

2. **`cleanup-all.ps1`** - Complete cleanup script
   - Deletes Kubernetes namespace
   - Removes Docker images
   - Cleans Minikube cache
   - **Run this before deploying!**

### Individual Component Scripts

3. **`deploy-all-k8s.ps1`** - Kubernetes deployment only
   - Builds images and deploys to K8s
   - Used internally by `deploy-complete.ps1`

4. **`seed-300-products.ps1`** - Seed catalog database
   - Inserts 300 products across 5 categories
   - Used internally by `deploy-complete.ps1`

5. **`test-all-services-k8s.ps1`** - E2E testing
   - Tests all 5 services
   - Verifies health endpoints
   - Used internally by `deploy-complete.ps1`

### Utility Scripts

6. **`health-check.ps1`** - Check single service health
7. **`health-check-all.ps1`** - Check all services health

## 🚀 Quick Start

### For Recording/Demo:

```powershell
# Navigate to scripts directory
cd eci-microservices\scripts

# Step 1: Clean up
.\cleanup-all.ps1

# Step 2: Deploy everything
.\deploy-complete.ps1
```

**Expected Result:**
- ✅ All 5 services deployed
- ✅ 300 products seeded
- ✅ 11/11 tests passed (100%)

**Time Required:** ~2-3 minutes

## 📊 Services Deployed

1. **Catalog Service** - Node.js + MySQL (Port 30090)
2. **Inventory Service** - Node.js + MySQL (Port 30091)
3. **Order Service** - FastAPI + MySQL (Port 30082)
4. **Payment Service** - FastAPI + PostgreSQL (Port 30086)
5. **Shipping Service** - FastAPI + PostgreSQL (Port 30085)

## 🔍 Verification Commands

```powershell
# Check all pods
kubectl get pods -n eci

# Check services
kubectl get svc -n eci

# Verify product count
kubectl exec -n eci deployment/catalog-mysql -- mysql -u root -prootpassword catalog_db -e "SELECT COUNT(*) FROM products;"

# View logs
kubectl logs -n eci -l app=catalog-service --tail=50
```

## 📝 Notes

- Scripts use relative paths - work from any location
- Automatic stabilization wait (45 seconds)
- All services include health checks
- Complete cleanup before redeployment
- 300 products seeded automatically (via init SQL in K8s ConfigMaps)
- Catalog database is pre-seeded during MySQL initialization
- Duplicate key warnings during seeding can be ignored (products already exist from init SQL)
