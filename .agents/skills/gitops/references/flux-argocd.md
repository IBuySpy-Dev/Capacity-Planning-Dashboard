# GitOps — Flux & ArgoCD Patterns

## Flux: Declarative GitOps for Kubernetes

### Installation

```bash
flux install --namespace=flux-system

flux bootstrap github \
  --owner=my-org \
  --repository=flux-config \
  --branch=main \
  --path=./clusters/prod \
  --personal
```

### Repository Structure

```
flux-config/
├── clusters/
│   ├── prod/
│   │   ├── flux-system/        # Flux operator config
│   │   ├── apps.yaml           # Application refs
│   │   └── infrastructure.yaml
│   └── staging/
└── apps/
    ├── backend/
    │   └── kustomization.yaml
    └── frontend/
        └── kustomization.yaml
```

### Kustomization

```yaml
# clusters/prod/apps.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
metadata:
  name: backend-app
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: flux-config
  path: ./apps/backend
  postBuild:
    substitute:
      env: prod
      image_tag: v1.2.3
```

### Multi-Environment Promotion

```
1. Developer commits to staging branch
2. Flux deploys to staging cluster
3. QA validates in staging
4. Developer opens PR: staging → prod
5. Approver merges PR
6. Flux detects change → deploys to prod
```

## ArgoCD: GitOps with Web UI

### Installation

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access web UI (admin / auto-generated password)
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

### Application Definition

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/app-config
    targetRevision: main
    path: apps/backend
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## Reconciliation Monitoring

```bash
# Flux
flux get kustomizations --watch
flux logs --follow

# ArgoCD
argocd app list
argocd app get my-app --refresh
```

### Common Drift Scenarios

| Scenario | Cause | Resolution |
|---|---|---|
| Manual `kubectl apply` in prod | Forgot to commit manifest | Revert, commit to Git, let operator reconcile |
| Image tag changed in registry | CI pushed without updating Git | Update tag in Git, reconcile |
| Cluster autoscaler changed replicas | Resource limits too high | Update limits in Git, reapply |
