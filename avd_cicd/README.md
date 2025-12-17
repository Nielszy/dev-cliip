# avd_cicd

Hi! This project contains the avd_cicd demo code.

To create a container registry for hosting the cEOS ARM container image on the minikube cluster perform the following commands on the Lima VM:

```sh
minikube addons enable registry -p dev-cliip
cd ~/container-images/
docker import cEOSarm-lab-4.34.3M.tar.tar ceos-arm-lab:4.34.3M
minikube image load ceos-arm-lab:4.34.3M -p dev-cliip
minikube ssh -p dev-cliip
docker tag ceos-arm-lab:4.34.3M IP_ADDRESS_REGISTRY_SERVICE/ceos-arm-lab:4.34.3M
docker push IP_ADDRESS_REGISTRY_SERVICE/ceos-arm-lab:4.34.3M
```
