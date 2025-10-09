# Monitoring

It is important to check the changes in a Helm values file before applying a new Helm release. Add the new Helm values file in this folder so it can easily be compared to the old values file:

```sh
HELM_CHART_VERSION=72.6.3

curl -sS "https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-${HELM_CHART_VERSION}/charts/kube-prometheus-stack/values.yaml" > kube-prometheus-stack-helm-values-v$HELM_CHART_VERSION.yaml
```
