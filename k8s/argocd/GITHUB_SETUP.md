# GitHub Repository Credentials for ArgoCD
# Follow these steps to fix the "app path does not exist" issue

## Step 1: Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name (e.g., "ArgoCD")
4. Select scopes: `repo` (full control)
5. Click "Generate token"
6. Copy the token (it will only show once!)

## Step 2: Add Token to ArgoCD

Run this command (replace YOUR_TOKEN with your GitHub token):

```bash
kubectl create secret generic github-creds \
  -n argocd \
  --from-literal=username=your-github-username \
  --from-literal=password=YOUR_TOKEN
```

## Step 3: Update ArgoCD Application

Edit the application to use the credentials:

```bash
kubectl edit application my-first-cicd -n argocd
```

Change the source section to include the secret:

```yaml
source:
  repoURL: https://github.com/spovedcloud-ger/my-first-cicd.git
  targetRevision: HEAD
  path: k8s/helm/my-first-cicd
  helm:
    valueFiles:
      - values-dev.yaml
  repoURL: https://github.com/spovedcloud-ger/my-first-cicd.git
  targetRevision: HEAD
  path: k8s/helm/my-first-cicd
  helm:
    valueFiles:
      - values-dev.yaml
  # Add this section:
  plugin:
    name: argocd-vault-plugin
```

Or use the CLI:

```bash
argocd repo add https://github.com/spovedcloud-ger/my-first-cicd.git --username YOUR_USERNAME --password YOUR_TOKEN
```

## Alternative: Use SSH Key

1. Generate SSH key: `ssh-keygen -t ed25519 -C "argocd@your-email"`
2. Add public key to GitHub: https://github.com/settings/keys
3. Add private key to ArgoCD:

```bash
kubectl create secret generic argocd-ssh-key \
  -n argocd \
  --from-file=ssh-privatekey=/path/to/id_ed25519
```

4. Update application to use SSH URL:
```yaml
source:
  repoURL: git@github.com:spovedcloud-ger/my-first-cicd.git
  sshKnownHosts: |
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
  secretRef:
    name: argocd-ssh-key
```

## After Setup

Once credentials are added, sync manually:

```bash
# Install argocd CLI
brew install argocd

# Sync app
argocd app sync my-first-cicd
```