#!/bin/bash
set -x

REPO_URL="https://$4@dev.azure.com/kamrunnaher26/votingapp/_git/votingapp"

git clone "$REPO_URL" /tmp/temp_repo
cd /tmp/temp_repo

sed -i "s|image:.*|image: newcicd1.azurecr.io/$2:$3|g" k8s-specifications/$1-deployment.yaml

git add .
git commit -m "Update Kubernetes manifest"
git push

rm -rf /tmp/temp_repo
