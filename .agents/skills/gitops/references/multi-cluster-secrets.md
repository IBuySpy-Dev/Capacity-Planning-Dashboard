# GitOps — Multi-Cluster Topology & Secrets Management

## Multi-Cluster Deployment

### Hub-and-Spoke Topology

Central hub cluster runs the GitOps controller; spoke clusters are managed targets.

```
                    ┌─ prod-us
                    ├─ prod-eu
       Hub Cluster ─┤
    (ArgoCD Server) ├─ staging
                    └─ dr (disaster recovery)
```

### Setup

```bash
# Register spoke clusters with ArgoCD
argocd cluster add my-spoke-us --name prod-us
argocd cluster list
```

```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-prod-us
spec:
  source:
    repoURL: https://github.com/my-org/app-config
    targetRevision: main
    path: apps/backend
  destination:
    server: https://prod-us-api:6443
    namespace: default
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-prod-eu
spec:
  source:
    repoURL: https://github.com/my-org/app-config
    targetRevision: main
    path: apps/backend
  destination:
    server: https://prod-eu-api:6443
    namespace: default
```

## Secrets Management

**Never commit plaintext secrets to Git.** Choose one of three approaches:

### Option 1: External Secrets Operator (Recommended)

Syncs secrets from Azure Key Vault, AWS Secrets Manager, or HashiCorp Vault.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: azure-keyvault
spec:
  provider:
    azurekv:
      tenantID: 12345678-1234-1234-1234-123456789012
      vaultURL: https://my-vault.vault.azure.net
      authSecretRef:
        clientID:
          name: azure-credentials
          key: client-id
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  secretStoreRef:
    name: azure-keyvault
    kind: SecretStore
  target:
    name: app-secrets
    creationPolicy: Owner
  data:
  - secretKey: db-password
    remoteRef:
      key: db-password
```

### Option 2: Sealed Secrets

Encrypt secrets locally; controller decrypts in cluster. Safe to commit to Git.

```bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/controller.yaml

echo -n mypassword | kubectl create secret generic app-secrets \
  --dry-run=client --from-file=password=/dev/stdin -o yaml \
  | kubeseal -f - > sealed-secret.yaml

git add sealed-secret.yaml && git commit -m "feat: add sealed app secret"
```

### Option 3: Kyverno Policy — Block Plaintext Secrets

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: block-unencrypted-secrets
spec:
  validationFailureAction: enforce
  rules:
  - name: require-sealed-label
    match:
      resources:
        kinds: [Secret]
    validate:
      message: "Secrets must carry the sealed=true label"
      pattern:
        metadata:
          labels:
            sealed: "true"
```

## Alert Rules

| Condition | Severity | Action |
|---|---|---|
| GitOps operator out of sync > 5 min | Warning | Page on-call; check operator logs |
| GitOps operator out of sync > 30 min | Critical | Incident; manual reconcile |
| DriftDetected event on prod cluster | Warning | Investigate and revert |
| Secret rotation failed | Critical | Rollback app deployment |
