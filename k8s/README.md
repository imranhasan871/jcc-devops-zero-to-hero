# Kubernetes Resources — JCC Platform

## What is Kubernetes?

Kubernetes (K8s) is an open-source **container orchestration platform**.
Where Docker runs a single container on a single machine, Kubernetes manages
many containers across many machines — handling scheduling, self-healing,
scaling, rolling updates, networking, and secrets management automatically.

## Core Vocabulary

| Term | What it is |
|------|-----------|
| **Cluster** | The complete Kubernetes installation: one or more machines managed as a unit. |
| **Node** | A physical or virtual machine that runs containers. A cluster has at least one control-plane node and one or more worker nodes. |
| **Pod** | The smallest deployable unit in K8s. A pod wraps one or more containers that share a network namespace and storage volumes. |
| **Deployment** | A higher-level object that manages a set of identical pods. It ensures the desired number of replicas is always running and handles rolling updates. |
| **Service** | A stable network endpoint (IP + DNS name) that load-balances traffic across a set of pods. Pods are ephemeral; Services are stable. |
| **Namespace** | A logical partition inside a cluster. Resources in different namespaces are isolated. Useful for separating environments (dev, staging, production) on the same cluster. |
| **ConfigMap** | Stores non-secret configuration as key-value pairs that can be injected into pods. |
| **Secret** | Like a ConfigMap but for sensitive data. Values are base64-encoded and access-controlled. |

## Directory Layout

```
k8s/
├── namespace.yaml          # The jcc-production namespace (Class 15)
├── README.md               # This file
├── backend/
│   ├── deployment.yaml     # App deployment (Class 16)
│   └── service.yaml        # ClusterIP service (Class 16)
└── config/
    ├── configmap.yaml      # Non-secret env vars (Class 17)
    └── secret.yaml         # Sensitive env vars (Class 17)
```

## Applying Resources

```bash
# Apply everything
kubectl apply -f k8s/

# Apply a single file
kubectl apply -f k8s/namespace.yaml

# Check what is running
kubectl get all -n jcc-production
```
