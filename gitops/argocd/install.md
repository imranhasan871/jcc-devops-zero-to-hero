# ArgoCD Installation

## Install ArgoCD into the cluster

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Wait for pods to be ready

```bash
kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=120s
```

## Access the ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# UI: https://localhost:8080
```

## Get the initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

## Login via CLI

```bash
argocd login localhost:8080 --username admin --insecure
```

## Change the admin password (do this immediately)

```bash
argocd account update-password
```
