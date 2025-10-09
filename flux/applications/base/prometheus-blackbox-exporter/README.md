# prometheus-blackbox-exporter

It is important to check the changes in a Helm values file before applying a new Helm release. Add the new Helm values file in this folder so it can easily be compared to the old values file:

```sh
BLACKBOX_EXPORTER_HELM_CHART_VERSION=11.4.0
curl -sS "https://raw.githubusercontent.com/prometheus-community/helm-charts/refs/tags/prometheus-blackbox-exporter-$BLACKBOX_EXPORTER_HELM_CHART_VERSION/charts/prometheus-blackbox-exporter/values.yaml" > prometheus-blackbox-exporter-helm-values-v$BLACKBOX_EXPORTER_HELM_CHART_VERSION.yaml
```
