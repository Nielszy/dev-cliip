# Cilium

It is important to check the changes in a Helm values file before applying a new Helm release. Add the new Helm values file in this folder so it can easily be compared to the old values file:

```sh
CILIUM_VERSION=1.17.4

curl -sS "https://raw.githubusercontent.com/cilium/cilium/v${CILIUM_VERSION}/install/kubernetes/cilium/values.yaml" > cilium-helm-values-v$CILIUM_VERSION.yaml
```
