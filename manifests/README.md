manifests/

This folder holds Kubernetes manifest files produced or used by CI pipelines for deployment to AKS.

Files:
- deployment.yml
- service.yml

Usage:
- CI pipelines upload or patch these files before deployment.
- Keep these manifests cluster-agnostic (use variables in pipelines or kustomize overlays for env-specific values).