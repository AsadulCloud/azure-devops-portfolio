#!/bin/bash
SRC="/mnt/d/Cloud Engaineering/Terraform/three-tier-architecture-demo"
DEST="/mnt/d/Cloud Engaineering/azure-devops-portfolio/15-Three-Tier-Architecture-Demo-Project"

# Create parent folder first
mkdir -p "$DEST"

for service in cart catalogue user payment shipping ratings dispatch web mongo mysql; do
  mkdir -p "$DEST/$service"
  rsync -av \
    --exclude='Dockerfile' \
    --exclude='*.yaml' \
    --exclude='*.yml' \
    --exclude='*.tf' \
    --exclude='.dockerignore' \
    "$SRC/$service/" "$DEST/$service/"
done

echo "✅ Done - only source code copied, no DevOps files"