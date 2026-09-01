# 🔍 Logging with EFK Stack on Azure Kubernetes Service (AKS)

A hands-on project to deploy a complete logging stack on **Azure AKS** using the **EFK** stack (Elasticsearch + Fluent Bit + Kibana).

This is the Azure-adapted version of a popular AWS EKS logging lab.

---

## 🚀 Why Logging Matters

- **Debugging**: Quickly find root causes of application issues
- **Auditing**: Track who did what and when
- **Performance**: Identify bottlenecks from log patterns
- **Security**: Detect suspicious or unauthorized activity

---

## 🛠️ Logging Stack Options

| Stack | Components | Notes |
|-------|------------|-------|
| **EFK** | Elasticsearch + Fluent Bit + Kibana | Lightweight & popular (this project) |
| **EFK** | Elasticsearch + Fluentd + Kibana | Heavier alternative |
| **ELK** | Elasticsearch + Logstash + Kibana | Classic version |
| **PLG** | Promtail + Loki + Grafana | Lightweight, great with Grafana |

---

## 🏠 Architecture

```
┌────────────────────────────────────────────────────┐
│                    AKS Cluster                       │
│                                                     │
│  ┌─────────────┐    ┌──────────────┐   ┌────────┐ │
│  │ Application │───▶│  Fluent Bit  │──▶│Elastic  │ │
│  │   Pods      │    │ (DaemonSet)  │   │search   │ │
│  └─────────────┘    └──────────────┘   └────┴───┘ │
│                                             │      │
│                                             ▼      │
│                                      ┌──────────┐  │
│                                      │  Kibana  │  │
│                                      └──────────┘  │
└────────────────────────────────────────────────────┘
```

---

## 📝 Prerequisites

- An existing **AKS cluster**
- `kubectl` configured to talk to the cluster
- Helm 3 installed
- Azure CLI (`az`) logged in

---

## 🚀 Step-by-Step Setup (Azure AKS)

### 1) Create Namespace for Logging

```bash
kubectl create namespace logging
```

### 2) Install Elasticsearch

```bash
helm repo add elastic https://helm.elastic.co
helm repo update

helm install elasticsearch \
  --set replicas=1 \
  --set volumeClaimTemplate.storageClassName=managed-csi \
  --set persistence.labels.enabled=true \
  elastic/elasticsearch -n logging
```

> **Note**: `managed-csi` is the default storage class on most AKS clusters.  
> If it does not exist, use `default` or check available storage classes with:  
> `kubectl get storageclass`

### 3) Get Elasticsearch Credentials

```bash
# Username
kubectl get secrets --namespace=logging elasticsearch-master-credentials \
  -o jsonpath='{.data.username}' | base64 -d
echo

# Password
kubectl get secrets --namespace=logging elasticsearch-master-credentials \
  -o jsonpath='{.data.password}' | base64 -d
echo
```

> Save the password — you will need it for Fluent Bit and for logging into Kibana.

### 4) Install Kibana

```bash
helm install kibana \
  --set service.type=LoadBalancer \
  elastic/kibana -n logging
```

### 5) Install Fluent Bit

Create a values file and put the Elasticsearch password in it:

```bash
cat > fluentbit-values.yaml <<EOF
config:
  outputs: |
    [OUTPUT]
        Name  es
        Match *
        Host  elasticsearch-master
        Port  9200
        HTTP_User elastic
        HTTP_Passwd <PASTE_PASSWORD_HERE>
        Logstash_Format On
        Retry_Limit False
        Suppress_Type_Name On
EOF
```

Then install:

```bash
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

helm install fluent-bit fluent/fluent-bit \
  -f fluentbit-values.yaml \
  -n logging
```

### 6) Access Kibana

```bash
# Get the external IP of Kibana
kubectl get svc -n logging kibana-kibana
```

Open in browser:

```
http://<EXTERNAL-IP>:5601
```

Login with:
- **Username**: `elastic`
- **Password**: the one you retrieved earlier

Then create a Data View (Index pattern) for `logstash-*` or `*` and start exploring logs.

---

## ✅ Verification Checklist

- [ ] Elasticsearch pods are Running
- [ ] Kibana is accessible via LoadBalancer
- [ ] Fluent Bit DaemonSet is running on all nodes
- [ ] You can see application logs in Kibana

```bash
# Useful commands
kubectl get pods -n logging
kubectl get svc -n logging
kubectl logs -n logging -l app.kubernetes.io/name=fluent-bit --tail=50
```

---

## 🧹 Clean Up

```bash
helm uninstall fluent-bit -n logging
helm uninstall kibana -n logging
helm uninstall elasticsearch -n logging

kubectl delete namespace logging
```

If you want to delete the whole AKS cluster later:

```bash
az aks delete --resource-group <your-rg> --name <your-cluster-name> --yes
```

---

## 📌 Azure-Specific Notes (What Changed from AWS)

| AWS (original)              | Azure (this version)                     |
|-----------------------------|------------------------------------------|
| `eksctl` + IAM roles        | AKS + Managed Identity (built-in)         |
| EBS CSI Driver + `gp2`      | Azure Disk CSI + `managed-csi`            |
| StorageClass `gp2`          | StorageClass `managed-csi` / `default`    |
| LoadBalancer                | Azure Load Balancer (same concept)        |
| Extra IAM role for CSI      | Not needed (AKS has CSI driver by default)|

On AKS the Azure Disk CSI driver is usually already enabled, so you do not need the extra IAM/role steps that are required on EKS.

---

## 🤞 Next Improvements

- [ ] Add Index Lifecycle Management (ILM) in Elasticsearch
- [ ] Secure Kibana with Azure AD / OAuth
- [ ] Switch Fluent Bit to use Azure Managed Identity
- [ ] Add Grafana + Loki as an alternative lightweight stack
- [ ] Ship logs to Azure Monitor / Log Analytics as well

---

> Part of my Azure DevOps & Cloud Engineering portfolio.  
> Looking for Junior Cloud / DevOps roles in Lisbon, Portugal.
