
# **Deploy Logging, Monitoring, and Observability Services via BuildPiper (BP)**

## **1. Create Namespaces via BP**

Create the following namespaces in the cluster:

```bash
logging
monitoring
observability
```

---

## **2. Create Environments via BP**

Create the following environments in BuildPiper:

| Environment       | Namespace     |
| ----------------- | ------------- |
| dev-logging       | logging       |
| dev-monitoring    | monitoring    |
| dev-observability | observability |

---
## **3. BP Deployment Template**

- Step 1: Workspace Clean

- Step 2: Clone Repo

- Step 3: Pre-Hook

- Step 4: Manifest Generate using Helm ---> Images:registry.buildpiper.in/k8s-deployment-using-helm:2.4.1.2

- Step 5: Kubernetes Manifest Apply ---> Images:registry.buildpiper.in/k8s-manifest-apply:2.3


---


## **4. Onboarding Services on BP**

### BP Services Structure

```bash
├── Logging
├── Monitoring
└── Observability
    ├── otel-collector-dev-uat-o11y
    ├── otel-operators-dev-uat-o11y
    └── tempo-dev-dev-uat-o11y

- You can also change the service names as per the requirement.
```

	
### **1. Onboard Monitoring Service**

- Configure Deployment Details

    <img width="2410" height="1456" alt="image" src="https://github.com/user-attachments/assets/2b161cdd-ec4f-45a2-bad9-01c5f7b88e70" />

> **Note:** The Helm release name must be set to vm for the Monitoring service.


- [Pre-Hook for CRDs and  Helm Dependencies Update](#4-bp-deployment-pre-hook-workflow)

    <img width="2350" height="1010" alt="image" src="https://github.com/user-attachments/assets/582f2ab5-4608-4621-bb64-671fe32ef4c0" />


>**Note:** For the Monitoring service, you must use both Pre-Hooks:
>- Pre-Hook for CRDs.
>- Pre-Hook for Helm dependency update

### **2. Onboard Logging Service**

- Configure Deployment Details

    <img width="2418" height="1402" alt="image" src="https://github.com/user-attachments/assets/0d8bc195-baef-4f47-bad2-658c6b37263a" />



- [Pre-Hook for Helm Dependencies Update](#2-pre-hook-for-all-services-helm-dependencies-update)


    <img width="2360" height="636" alt="image" src="https://github.com/user-attachments/assets/186bd14f-baa5-4fad-8575-266ca7d7108d" />


> NOTE;-
> Apply the same setup for Observability

## **5. BP Deployment Pre-Hook Workflow**

### **1. Monitoring CRDs Pre-Hook**

#### **Script: `pre-hook-crd.sh`**

```bash

#!/bin/bash

gitUrl=$1
gitBranch=$2
crdfile=$3

if [[ -z "$gitUrl" || -z "$gitBranch" || -z "$crdfile" ]]; then
    echo "Error: Missing arguments!"
    echo "Usage: $0 <gitUrl> <gitBranch> <crdfile>"
    exit 1
fi

export KUBECONFIG=~/.kube/apnamart-gcp-devuat-cluster/config
LOG_FILE="crd_apply.log"
> "$LOG_FILE"

echo "Applying Prometheus CRDs... logs will be saved in $LOG_FILE"

CRDS=(
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml"
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml"
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml"
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml"
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml"
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml"
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml"
)

for crd in "${CRDS[@]}"; do
    echo "Applying $crd ..."
    kubectl apply --server-side --validate=false -f "$crd" >> "$LOG_FILE" 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Failed: $crd (see $LOG_FILE for details)"
    else
        echo "Success: $crd"
    fi
done

echo "Applying VictoriaMetrics CRDs from private repo..."

WORKDIR="/tmp/apnamart-gcp"

if [[ -d "$WORKDIR" ]]; then
    cd "$WORKDIR" && git pull origin "$gitBranch" >> "$LOG_FILE" 2>&1
else
    git clone "$gitUrl" -b "$gitBranch" "$WORKDIR" >> "$LOG_FILE" 2>&1
    cd "$WORKDIR"
fi

if [[ -f "$crdfile" ]]; then
    echo "Applying $crdfile ..."
    details=$(kubectl apply -f "$crdfile" 2>&1 | tee -a "$LOG_FILE")
    if [[ $? -ne 0 ]]; then
        echo "Failed: $crdfile"
        echo "Details: $details"
    else
        echo "Success: $crdfile"
        echo "Details: $details"
    fi
else
    echo "$crdfile not found in repo!"
fi

echo "All CRDs processed. Check $LOG_FILE for details."
rm -rf "$WORKDIR"


```

#### **Usage**


```bash

./pre-hook-crd.sh git@github.com-apnamart:ot-client/apnamart-gcp.git 011y-victoriametrics-crd victoriametrics-crd.yaml

```

> This ensures all **Prometheus CRDs** and **VictoriaMetrics CRDs** are applied before Helm deployment of the monitoring service.

  
---

### **2. Pre-Hook for All Services (Helm Dependencies Update)**

  
Before generating manifests for **any service** (logging, monitoring, observability), update Helm dependencies:


```bash

helm dep update /root/.codebase/workspaces/dev/dev-uat-monitoring/service/monitoring/deployment_name/monitoring-dev-uat-monitoring/workspace/apnamart-gcp/Victoriametrics

```


---

## **6. SSH Setup for Private Repo**

```bash
ssh-keygen -t ed25519 -C "apnamart-o11y" -f ~/.ssh/id_ed25519_011y
```

Update `~/.ssh/config` from rootand ubuntu both users :-

```
Host github.com-apnamart
    HostName github.com
    User git
    IdentityFile /home/ubuntu/.ssh/id_ed25519_011y
```

---

## **7. Troubleshooting Node Exporter ConfigMap Deployment**

1. Install `yq` if not present:
    
```bash
sudo snap install yq
```

2. Extract specific ConfigMap:
    
```bash
cd ~/.common/workspaces/dev/dev-uat-monitoring/service/monitoring/deployment_name/monitoring-dev-uat-monitoring/data/k8s_manifests

```

```bash
cat 0.yaml | yq e 'select(.kind=="ConfigMap" and .metadata.name=="vm-node-exporter-full")' > vm-node-exporter-full.yaml
```

```bash
cp vm-node-exporter-full.yaml /home/ubuntu
```

```bash
kubectl apply -f vm-node-exporter-full.yaml --server-side --force-conflicts
```

---

This SOP ensures:
- Monitoring CRDs are applied safely before deployment.
