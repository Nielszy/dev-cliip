# NetBox

NetBox is deployed with the official [NetBox Helm chart](https://github.com/netbox-community/netbox-chart), using the NetBox image that comes with the chart and the bundled PostgreSQL and Valkey subcharts.

It is important to check the changes in a Helm values file before applying a new Helm release. Add the new Helm values file in this folder so it can easily be compared to the old values file:

```sh
NETBOX_HELM_CHART_VERSION=8.3.100
helm show values oci://ghcr.io/netbox-community/netbox-chart/netbox --version $NETBOX_HELM_CHART_VERSION > netbox-helm-values-v$NETBOX_HELM_CHART_VERSION.yaml
```
