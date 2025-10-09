# ingress-nginx

It is important to check the changes in a Helm values file before applying a new Helm release. Add the new Helm values file in this folder so it can easily be compared to the old values file:

```bash
CHART_VERSION=4.12.2
curl -sS https://raw.githubusercontent.com/kubernetes/ingress-nginx/helm-chart-$CHART_VERSION/charts/ingress-nginx/values.yaml > ingress-nginx-helm-values-v$CHART_VERSION.yaml
```
