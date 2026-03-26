#!/bin/bash
# ArgoCD Installation Script for Docker Desktop Kubernetes

set -e

echo "=== ArgoCD Installation Script ==="

# 1. Create argocd namespace
echo "[1/5] Creating argocd namespace..."
kubectl create namespace argocd || echo "Namespace already exists"

# 2. Install ArgoCD
echo "[2/5] Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for ArgoCD to be ready
echo "[3/5] Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# 4. Get admin password
echo "[4/5] Getting admin password..."
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $PASSWORD"

# 5. Expose ArgoCD via NodePort
echo "[5/5] Exposing ArgoCD UI..."
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'

echo ""
echo "=== Installation Complete ==="
echo "ArgoCD UI: http://localhost:30080"
echo "Username: admin"
echo "Password: $PASSWORD"
echo ""
echo "To connect your app, apply the Application manifest:"
echo "  kubectl apply -f k8s/argocd/application.yaml"