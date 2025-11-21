# Kubernetes Secrets Setup

## For Local Development

**IMPORTANT**: Never commit actual secrets to git!

### Quick Setup

1. Copy example files:
   ```bash
   cp k8s/postgres/secret.yaml.example k8s/postgres/secret.yaml
   cp k8s/app/secret.yaml.example k8s/app/secret.yaml
   ```

2. Edit the files and replace `CHANGE_ME_SECURE_PASSWORD` with your actual passwords:
   ```bash
   # Use a secure password generator
   openssl rand -base64 32
   ```

3. Deploy to Kubernetes:
   ```bash
   kubectl apply -f k8s/postgres/secret.yaml
   kubectl apply -f k8s/app/secret.yaml
   ```

### For Docker Desktop / Minikube Testing

For local testing, you can use simple passwords:
```bash
# postgres/secret.yaml
POSTGRES_PASSWORD: postgres123

# app/secret.yaml
SPRING_DATASOURCE_PASSWORD: postgres123
```

## For CI/CD / Production

Secrets are automatically created by GitHub Actions workflows using GitHub Secrets.

### Required GitHub Secrets

Set these in your repository: Settings > Secrets and variables > Actions

| Secret Name | Description |
|------------|-------------|
| `POSTGRES_DB` | Database name (e.g., `coffeequeue`) |
| `POSTGRES_USER` | Database username (e.g., `postgres`) |
| `POSTGRES_PASSWORD` | Strong database password |

### How CI/CD Creates Secrets

The deployment workflows (`deploy-dev.yml`, `deploy-prod.yml`) automatically create Kubernetes secrets from GitHub Secrets:

```yaml
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_DB="$POSTGRES_DB" \
  --from-literal=POSTGRES_USER="$POSTGRES_USER" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -
```

This ensures:
- No secrets in git repository
- Different secrets per environment
- Easy password rotation via GitHub UI
- Secrets encrypted at rest in GitHub

## Security Best Practices

1. **Never commit secret.yaml files** - They're in .gitignore
2. **Use strong passwords** - Minimum 16 characters, use password manager
3. **Rotate regularly** - Change passwords every 90 days
4. **Different passwords per environment** - Dev passwords ≠ Prod passwords
5. **Use external secret management for production** - Consider AWS Secrets Manager, HashiCorp Vault, or Azure Key Vault

## Troubleshooting

### Check if secrets exist:
```bash
kubectl get secrets -n coffee-queue
```

### View secret (base64 encoded):
```bash
kubectl get secret postgres-secret -n coffee-queue -o yaml
```

### Delete and recreate:
```bash
kubectl delete secret postgres-secret -n coffee-queue
kubectl apply -f k8s/postgres/secret.yaml
```

# Secrets (Deprecated)

See root README (Secrets section).

Example manual secret:
```bash
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_DB=coffeequeue \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=CHANGE_ME \
  -n coffee-queue --dry-run=client -o yaml | kubectl apply -f -
```
