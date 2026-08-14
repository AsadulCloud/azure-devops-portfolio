Kubernetes Ingress

This folder contains ingress YAMLs used for routing traffic to applications running on AKS for demo projects.

Files:
- aks-cicd-app-ingress.yaml
- task-ingress.yml
- task-manager-ingress-*.yml

Notes:
- These manifests are intended for demo environments. Review hostnames and annotations before applying to a real cluster.
- Use kubectl apply -f <file> to test and kubectl describe ingress <name> to debug.