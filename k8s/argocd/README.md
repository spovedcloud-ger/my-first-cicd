# GitOps with ArgoCD

## What is GitOps?

GitOps is a way to manage Kubernetes deployments using Git as the single source of truth.

**Traditional Deployment:**
```
You → kubectl apply → Kubernetes
```

**GitOps:**
```
You → Git Commit → ArgoCD watches Git → syncs to Kubernetes
```

## How It Works

1. **Push** your Kubernetes manifests to GitHub
2. **ArgoCD** watches your Git repository
3. **When you push changes**, ArgoCD automatically syncs them to your cluster
4. **If someone modifies resources manually**, ArgoCD detects drift and can auto-heal

## Quick Start

### Access ArgoCD UI

```
URL: http://localhost:30080
Username: admin
Password: (get from below)
```

Get password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Connect Your App

Apply the Application manifest:
```bash
kubectl apply -f k8s/argocd/application.yaml
```

### How to Deploy Changes

**Option 1: Update manifests in Git**
```bash
# Edit a manifest
vim k8s/manifests/deployment.yaml

# Commit and push
git add .
git commit -m "Update replicas to 3"
git push

# ArgoCD will automatically sync!
```

**Option 2: Manual sync (via UI)**
1. Open ArgoCD UI
2. Click on your application
3. Click "Sync"

## ArgoCD Application Manifest

The `application.yaml` tells ArgoCD:
- **Where** your manifests are (Git repo + path)
- **Where** to deploy (namespace)
- **How** to sync (auto/manual, prune, etc.)

## Useful Commands

```bash
# List applications
kubectl get applications -n argocd

# Get app status
kubectl get application my-first-cicd -n argocd

# Sync manually
argocd app sync my-first-cicd

# View app diff (what will change)
argocd app diff my-first-cicd

# Delete app (and resources)
kubectl delete -f k8s/argocd/application.yaml
```

## Key Concepts

| Term | Meaning |
|------|---------|
| **Application** | A GitOps app managed by ArgoCD |
| **Sync** | Process of applying Git changes to cluster |
| **Drift** | When cluster state differs from Git |
| **Self-Heal** | ArgoCD automatically fixes drift |
| **Prune** | Delete resources removed from Git |

## Benefits

- ✅ **Single source of truth** - All configs in Git
- ✅ **Audit trail** - Every change is a Git commit
- ✅ **Rollback** - Easy to revert to previous version
- ✅ **Drift detection** - Knows when cluster diverges from Git
- ✅ **Multi-environment** - Can manage dev/staging/prod