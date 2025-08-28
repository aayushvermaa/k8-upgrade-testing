
# **Deploy Logging, Monitoring, and Observability Services via BuildPiper (BP)**

## **Prerequisites**

### 1. **EBS-CSI Plugin**

   * Verify if the **EBS CSI driver plugin** is enabled in the cluster.
   * Run:

     ```bash
     kubectl get pods -n kube-system | grep ebs-csi
     ```
   * If not installed, enable it via your cloud provider or Helm chart (depends on infra).

### 2. **yq Installed (for troubleshooting)**

   * Check:

     ```bash
     yq --version
     ```
   * If not installed:

     ```bash
     sudo snap install yq
     ```

---




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
| **Field**                  | **Logging Service** | **Monitoring Service** | **Observability Service** |                  |           |
|-----------------------------|------------------|----------------------|--------------------------|------------------|-----------|
|      Sub services           |                  |                      | **otel-collector**       | **otel-operators** | **tempo** |
| **Deployment Name**         | logging-dev      | monitoring-dev       | otel-collector-dev       | otel-operators-dev | tempo-dev |
| **Service Name**            | logging-dev      | monitoring-dev       | otel-collector-dev       | otel-operators-dev | tempo-dev |
| **Image Pull Policy**       | Always           | Always               | Always                   | Always            | Always    |
| **Resource Kind**           | Please Select    | Please Select        | Please Select            | Please Select     | Please Select |
| **Widget Data**             | logging-dev      | monitoring-dev       | otel-collector-dev       | otel-operators-dev | tempo-dev |
| **Define Raw Key Value Pairs** | No (toggle off) | No (toggle off)     | No (toggle off)          | No (toggle off)   | No (toggle off) |


> **Note:** The values provided above are **suggested names**. You may change them according to your project requirements.

---
	
### **1. Onboard Monitoring Service**

- Configure Deployment Details

    <img width="2410" height="1456" alt="image" src="https://github.com/user-attachments/assets/2b161cdd-ec4f-45a2-bad9-01c5f7b88e70" />

> **Note:** The Helm release name must be set to `vm` for the Monitoring service.



- [Pre-Hook for CRDs and  Helm Dependencies Update](#4-bp-deployment-pre-hook-workflow)

	<img width="2310" height="1098" alt="image" src="https://github.com/user-attachments/assets/d6862972-3a9a-40e7-9c59-8f83c4d27d0e" />


>**Note:** For the Monitoring service, you must use both Pre-Hooks:
>- Pre-Hook for CRDs.
>- Pre-Hook for Helm dependency update

### **2. Onboard Logging Service**

- Configure Deployment Details

    <img width="2418" height="1402" alt="image" src="https://github.com/user-attachments/assets/0d8bc195-baef-4f47-bad2-658c6b37263a" />



- [Pre-Hook for Helm Dependencies Update](#2-pre-hook-for-all-services-helm-dependencies-update)


    <img width="2360" height="636" alt="image" src="https://github.com/user-attachments/assets/186bd14f-baa5-4fad-8575-266ca7d7108d" />


> NOTE:-
> Apply the same setup for Observability service and sub service

## **5. BP Deployment Pre-Hook Workflow**

### **1. Monitoring CRDs Pre-Hook**

#### **Script: `prehook-crd-apply.sh`**

```bash
#!/bin/bash

Cluster_Name=$1
VM_VERSION=$2

#VM_VERSION="0.58.0"

if [[ -z "$Cluster_Name" || -z "$VM_VERSION" ]]; then
  echo "Usage: $0 <Cluster_Name> <VM_VERSION>"
  exit 1
fi

export KUBECONFIG=~/.kube/${Cluster_Name}/config

LOG_FILE="crd_apply.log"
> "$LOG_FILE"

echo "Applying CRDs... logs will be saved in $LOG_FILE"

PROM_CRDS=(
  "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml"
  "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml"
  "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml"
  "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml"
  "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml"
  "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml"
  "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml"
)

for crd in "${PROM_CRDS[@]}"; do
  echo "Applying $crd ..."
  kubectl apply --server-side --validate=false -f "$crd" >> "$LOG_FILE" 2>&1
  if [[ $? -ne 0 ]]; then
    echo "Failed: $crd (see $LOG_FILE for details)"
  else
    echo "Success: $crd"
  fi
done


VM_CRD="https://raw.githubusercontent.com/VictoriaMetrics/helm-charts/refs/tags/victoria-metrics-k8s-stack-${VM_VERSION}/charts/victoria-metrics-operator/crd.yaml"

echo "Applying VictoriaMetrics CRD ($VM_VERSION) ..."
details=$(kubectl apply --server-side --validate=false -f "$VM_CRD" 2>&1 | tee -a "$LOG_FILE")

if [[ $? -ne 0 ]]; then
  echo "Failed: $VM_CRD"
  echo "Details: $details"
else
  echo "Success: $VM_CRD"
  echo "Details: $details"
fi

echo "All CRDs processed. Check $LOG_FILE for details."

```

#### **Usage**


```bash

./prehook-crd-apply.sh <Cluster_Name> <VM_VERSION>

```

> This ensures all **Prometheus CRDs** and **VictoriaMetrics CRDs** are applied before Helm deployment of the monitoring service.

  
---

### **2. Pre-Hook for All Services (Helm Dependencies Update)**

  
Before generating manifests for **any service** (logging, monitoring, observability), update Helm dependencies:


```bash

helm dep update /root/.codebase/workspaces/dev/dev-uat-monitoring/service/monitoring/deployment_name/monitoring-dev-uat-monitoring/workspace/apnamart-gcp/Victoriametrics

```


---


## **6. Troubleshooting Node Exporter ConfigMap Deployment**

If you are facing this issue during the Kubernetes Manifest Apply step, then…

<img width="2836" height="250" alt="image" src="https://github.com/user-attachments/assets/a902fc6b-9158-47cf-9c21-4f861e5dc367" />



1. [Install `yq` if not present:](#2-yq-installed-for-troubleshooting)
    
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
