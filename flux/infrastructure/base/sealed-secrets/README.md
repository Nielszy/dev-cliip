# Sealed Secrets

It is important to check the changes in a Helm values file before applying a new Helm release. Add the new Helm values file in this folder so it can easily be compared to the old values file:

```sh
SEALED_SECRETS_VERSION=helm-v2.17.7

curl -sS "https://raw.githubusercontent.com/bitnami-labs/sealed-secrets/refs/tags/${SEALED_SECRETS_VERSION}/helm/sealed-secrets/values.yaml" > sealed-secrets-helm-values-$SEALED_SECRETS_VERSION.yaml
```
