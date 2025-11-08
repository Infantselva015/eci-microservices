# ECI Platform - Kubernetes Deployment Script
# Automates deployment to Minikube

param(
    [switch]$Install,
    [switch]$Build,
    [switch]$Deploy,
    [switch]$Test,
    [switch]$Cleanup,
    [switch]$All
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ECI Platform - Kubernetes Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$namespace = "eci-platform"
$basePath = Split-Path -Parent $PSScriptRoot

function Install-Prerequisites {
    Write-Host "[1/3] Checking prerequisites..." -ForegroundColor Yellow
    
    # Check Minikube
    try {
        minikube version | Out-Null
        Write-Host "  ✓ Minikube installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Minikube not found. Install with: choco install minikube" -ForegroundColor Red
        return $false
    }
    
    # Check kubectl
    try {
        kubectl version --client | Out-Null
        Write-Host "  ✓ kubectl installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ kubectl not found. Install with: choco install kubernetes-cli" -ForegroundColor Red
        return $false
    }
    
    # Check Kompose
    try {
        kompose version | Out-Null
        Write-Host "  ✓ Kompose installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Kompose not found. Install with: choco install kubernetes-kompose" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Start-MinikubeCluster {
    Write-Host "`n[2/3] Starting Minikube cluster..." -ForegroundColor Yellow
    
    $status = minikube status 2>&1
    if ($status -match "Running") {
        Write-Host "  ✓ Minikube already running" -ForegroundColor Green
        return $true
    }
    
    Write-Host "  Starting Minikube (this may take a few minutes)..." -ForegroundColor Cyan
    minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Minikube started successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ✗ Failed to start Minikube" -ForegroundColor Red
        return $false
    }
}

function Set-DockerEnvironment {
    Write-Host "`n[3/3] Configuring Docker environment..." -ForegroundColor Yellow
    
    & minikube -p minikube docker-env --shell powershell | Invoke-Expression
    Write-Host "  ✓ Docker configured to use Minikube daemon" -ForegroundColor Green
}

function Build-ServiceImages {
    Write-Host "`n[BUILD] Building Docker images in Minikube..." -ForegroundColor Yellow
    
    Set-Location $basePath
    
    Write-Host "  Building all service images..." -ForegroundColor Cyan
    docker-compose build
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n  ✓ All images built successfully" -ForegroundColor Green
        
        Write-Host "`n  Built images:" -ForegroundColor Cyan
        docker images | Select-String "eci-"
        return $true
    } else {
        Write-Host "  ✗ Image build failed" -ForegroundColor Red
        return $false
    }
}

function Convert-ToKubernetes {
    Write-Host "`n[CONVERT] Converting Docker Compose to Kubernetes..." -ForegroundColor Yellow
    
    Set-Location $basePath
    
    # Create output directory
    $k8sDir = Join-Path $basePath "k8s-generated"
    if (Test-Path $k8sDir) {
        Remove-Item $k8sDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $k8sDir | Out-Null
    
    # Convert
    Write-Host "  Running kompose convert..." -ForegroundColor Cyan
    kompose convert -f docker-compose.yml -o k8s-generated/
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Conversion successful" -ForegroundColor Green
        
        # Fix image pull policy
        Write-Host "  Updating imagePullPolicy to Never..." -ForegroundColor Cyan
        Get-ChildItem "$k8sDir/*-deployment.yaml" | ForEach-Object {
            (Get-Content $_) -replace 'imagePullPolicy: ""', 'imagePullPolicy: Never' | Set-Content $_
        }
        
        Write-Host "  ✓ Image pull policy updated" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ✗ Conversion failed" -ForegroundColor Red
        return $false
    }
}

function Deploy-ToKubernetes {
    Write-Host "`n[DEPLOY] Deploying to Kubernetes..." -ForegroundColor Yellow
    
    Set-Location $basePath
    
    # Create namespace
    Write-Host "  Creating namespace: $namespace..." -ForegroundColor Cyan
    kubectl create namespace $namespace 2>$null
    
    # Apply manifests
    Write-Host "  Applying Kubernetes manifests..." -ForegroundColor Cyan
    kubectl apply -f k8s-generated/ -n $namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Deployment initiated" -ForegroundColor Green
        
        Write-Host "`n  Waiting for pods to be ready (this may take 2-3 minutes)..." -ForegroundColor Cyan
        Start-Sleep -Seconds 10
        
        # Wait for pods
        $timeout = 180
        $elapsed = 0
        while ($elapsed -lt $timeout) {
            $pods = kubectl get pods -n $namespace --no-headers 2>$null
            $totalPods = ($pods | Measure-Object).Count
            $runningPods = ($pods | Select-String "Running" | Measure-Object).Count
            
            Write-Host "  Pods running: $runningPods/$totalPods" -ForegroundColor Cyan
            
            if ($runningPods -eq $totalPods -and $totalPods -gt 0) {
                Write-Host "`n  ✓ All pods are running!" -ForegroundColor Green
                return $true
            }
            
            Start-Sleep -Seconds 10
            $elapsed += 10
        }
        
        Write-Host "`n  ⚠ Timeout waiting for pods. Check status with: kubectl get pods -n $namespace" -ForegroundColor Yellow
        return $true
    } else {
        Write-Host "  ✗ Deployment failed" -ForegroundColor Red
        return $false
    }
}

function Show-DeploymentStatus {
    Write-Host "`n[STATUS] Current deployment status:" -ForegroundColor Yellow
    
    Write-Host "`nPods:" -ForegroundColor Cyan
    kubectl get pods -n $namespace
    
    Write-Host "`nServices:" -ForegroundColor Cyan
    kubectl get svc -n $namespace
    
    Write-Host "`nPersistent Volume Claims:" -ForegroundColor Cyan
    kubectl get pvc -n $namespace
}

function Seed-Databases {
    Write-Host "`n[SEED] Seeding databases..." -ForegroundColor Yellow
    
    # Get pod names
    Write-Host "  Getting pod names..." -ForegroundColor Cyan
    $catalogPod = kubectl get pods -n $namespace -l io.kompose.service=catalog-service -o jsonpath='{.items[0].metadata.name}' 2>$null
    $inventoryPod = kubectl get pods -n $namespace -l io.kompose.service=inventory-service -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($catalogPod) {
        Write-Host "  Seeding catalog database..." -ForegroundColor Cyan
        kubectl exec -n $namespace $catalogPod -- npm run seed
        Write-Host "  ✓ Catalog database seeded" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Catalog pod not found" -ForegroundColor Yellow
    }
    
    if ($inventoryPod) {
        Write-Host "  Seeding inventory database..." -ForegroundColor Cyan
        kubectl exec -n $namespace $inventoryPod -- npm run seed
        Write-Host "  ✓ Inventory database seeded" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Inventory pod not found" -ForegroundColor Yellow
    }
}

function Start-PortForwarding {
    Write-Host "`n[ACCESS] Starting port forwarding..." -ForegroundColor Yellow
    Write-Host "  Run these commands in separate terminals:" -ForegroundColor Cyan
    
    $services = @(
        @{Name="catalog"; Port=8090},
        @{Name="inventory"; Port=8081},
        @{Name="order"; Port=8082},
        @{Name="payment"; Port=8086},
        @{Name="shipping"; Port=8085}
    )
    
    foreach ($svc in $services) {
        Write-Host "  kubectl port-forward -n $namespace svc/$($svc.Name)-service $($svc.Port):$($svc.Port)" -ForegroundColor White
    }
    
    Write-Host "`n  Or use NodePort (automatic):" -ForegroundColor Cyan
    Write-Host "  minikube service catalog-service -n $namespace --url" -ForegroundColor White
}

function Test-Services {
    Write-Host "`n[TEST] Testing service health..." -ForegroundColor Yellow
    
    Write-Host "  Starting port-forward for testing..." -ForegroundColor Cyan
    Start-Job -ScriptBlock { kubectl port-forward -n eci-platform svc/catalog-service 8090:8090 } | Out-Null
    Start-Sleep -Seconds 5
    
    $services = @(
        @{Name="Catalog"; Port=8090; Path="/health"},
        @{Name="Inventory"; Port=8081; Path="/health"},
        @{Name="Order"; Port=8082; Path="/health"},
        @{Name="Payment"; Port=8086; Path="/health"},
        @{Name="Shipping"; Port=8085; Path="/health"}
    )
    
    foreach ($svc in $services) {
        try {
            $response = Invoke-RestMethod "http://localhost:$($svc.Port)$($svc.Path)" -TimeoutSec 5
            Write-Host "  ✓ $($svc.Name) Service - Healthy" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ $($svc.Name) Service - Not accessible (port-forward required)" -ForegroundColor Yellow
        }
    }
    
    # Stop port-forward jobs
    Get-Job | Where-Object { $_.State -eq "Running" } | Stop-Job
    Get-Job | Remove-Job
}

function Remove-Deployment {
    Write-Host "`n[CLEANUP] Removing deployment..." -ForegroundColor Yellow
    
    $confirm = Read-Host "  Are you sure you want to delete namespace '$namespace'? (y/N)"
    if ($confirm -ne "y") {
        Write-Host "  Cleanup cancelled" -ForegroundColor Yellow
        return
    }
    
    kubectl delete namespace $namespace
    Write-Host "  ✓ Namespace deleted" -ForegroundColor Green
    
    $stopMinikube = Read-Host "  Stop Minikube? (y/N)"
    if ($stopMinikube -eq "y") {
        minikube stop
        Write-Host "  ✓ Minikube stopped" -ForegroundColor Green
    }
}

# Main execution
try {
    if ($All) {
        $Install = $true
        $Build = $true
        $Deploy = $true
        $Test = $true
    }
    
    if ($Install -or (-not $Build -and -not $Deploy -and -not $Test -and -not $Cleanup)) {
        if (-not (Install-Prerequisites)) { exit 1 }
        if (-not (Start-MinikubeCluster)) { exit 1 }
        Set-DockerEnvironment
    }
    
    if ($Build) {
        Set-DockerEnvironment
        if (-not (Build-ServiceImages)) { exit 1 }
        if (-not (Convert-ToKubernetes)) { exit 1 }
    }
    
    if ($Deploy) {
        if (-not (Deploy-ToKubernetes)) { exit 1 }
        Show-DeploymentStatus
        Seed-Databases
        Start-PortForwarding
    }
    
    if ($Test) {
        Test-Services
    }
    
    if ($Cleanup) {
        Remove-Deployment
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "✓ Deployment script completed!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Port-forward services (see commands above)" -ForegroundColor White
    Write-Host "  2. Test health: Invoke-RestMethod http://localhost:8090/health" -ForegroundColor White
    Write-Host "  3. View pods: kubectl get pods -n $namespace" -ForegroundColor White
    Write-Host "  4. View logs: kubectl logs -n $namespace <pod-name>" -ForegroundColor White
    Write-Host "  5. Dashboard: minikube dashboard" -ForegroundColor White
    
} catch {
    Write-Host "`n✗ Error: $_" -ForegroundColor Red
    exit 1
}
