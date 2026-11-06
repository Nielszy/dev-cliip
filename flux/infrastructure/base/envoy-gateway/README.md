# Envoy Gateway

[Envoy Gateway](https://gateway.envoyproxy.io/) implements the Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/) and routes traffic into the K8s cluster. The Helm chart also installs the Gateway API CRDs.

It is important to check the changes in a Helm values file before applying a new Helm release. Add the new Helm values file in this folder so it can easily be compared to the old values file. The values file in the Envoy Gateway Git repository is a template, so get the values from the published chart instead:

```sh
ENVOY_GATEWAY_VERSION=v1.9.3

helm show values oci://docker.io/envoyproxy/gateway-helm --version ${ENVOY_GATEWAY_VERSION} > envoy-gateway-helm-values-${ENVOY_GATEWAY_VERSION}.yaml
```
