#!/bin/bash
# =============================================================
# GitOps Image Tag Updater
# Updates the image tag in k8s/manifests/deployment.yaml
# Called by GitHub Actions after a new image is pushed to GHCR
# =============================================================

set -e

IMAGE_NAME="${1:-ghcr.io/spovedcloud-ger/my-first-cicd}"
NEW_TAG="${2:-latest}"
MANIFEST_FILE="k8s/manifests/deployment.yaml"

if [ -z "$2" ]; then
  echo "Usage: $0 <image-name> <new-tag>"
  echo "Example: $0 ghcr.io/spovedcloud-ger/my-first-cicd abc1234"
  exit 1
fi

echo "=== GitOps: Updating Image Tag ==="
echo "Image: $IMAGE_NAME"
echo "New Tag: $NEW_TAG"
echo "File: $MANIFEST_FILE"

# Check if file exists
if [ ! -f "$MANIFEST_FILE" ]; then
  echo "ERROR: Manifest file not found: $MANIFEST_FILE"
  exit 1
fi

# Show current image
CURRENT=$(grep "image:" "$MANIFEST_FILE" | head -1 | tr -d '[:space:]')
echo "Current: $CURRENT"

# Replace the image tag (handles both :latest and :sha formats)
sed -i "s|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${NEW_TAG}|g" "$MANIFEST_FILE"

# Verify the change
NEW=$(grep "image:" "$MANIFEST_FILE" | head -1 | tr -d '[:space:]')
echo "Updated: $NEW"

echo ""
echo "✅ Image tag updated successfully"
echo "ArgoCD will detect this change and auto-sync to the cluster"
