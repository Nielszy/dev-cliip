# dev-cliip (Development Cloud Infrastructure Intelligence Platform)

## Introduction

This project aims to provide a local development platform that replicates the key tools commonly used in modern production environments for network and infrastructure automation, monitoring, and observability. Once the platform is up and running, all tools are readily available on static endpoints—giving you a consistent and accessible environment to develop and test your automation and observability workflows.

This guide provides step-by-step instructions for creating a local development `dev` cloud infrastructure intelligence platform `cliip` on a Linux VM (guest) running on you Mac (host).

`dev-cliip` supports multiple use cases, including:

- Learning NetDevOps practices and testing network automation workflows in a local environment, at zero cost.
- Deploying a network automation, monitoring, and observability platform on a local Kubernetes cluster, including [NetBox](https://github.com/netbox-community/netbox), [Prometheus](https://github.com/prometheus/prometheus), Prometheus Exporters, [Grafana](https://github.com/grafana/grafana), [clabernetes](https://github.com/srl-labs/clabernetes).
- Creating container-based network labs with Containerlab using network operating systems like Arista cEOS and Nokia SR Linux.
- Developing and testing network automation, monitoring, and observability solutions.

### Why run dev-cliip on a Linux VM?

Why run dev-cliip on a Lima VM and not use Colima or alternatives to run all dev-cliip components? For now I chose the Lima approach for the following reasons:

- For projects like this I want to use free and open source software as much as possible. Lima provides a fully open source alternative for running Linux VMs on macOS compared to proprietary software like [OrbStack](https://orbstack.dev/).
- [Containerlab](https://containerlab.dev/macos/) is integrated into dev-cliip for network topology simulations. Since the containerlab binary is only distributed as a Linux package (deb/rpm/apk) without native macOS support, running it within a Linux VM is the most straightforward approach.
- I aimed to keep the setup as simple as possible. After testing alternatives like [Colima](https://github.com/abiosoft/colima), I found that running dev-cliip on a Lima VM provided the most straightforward experience with fewer configuration issues to troubleshoot.
- The VM approach provides clear isolation between dev-cliip and your Mac, making it trivial to destroy the entire environment and start fresh whenever needed. This well-defined boundary is particularly valuable for learning and experimentation, as you can freely break things without worrying about impacting your host system or leaving behind configuration remnants.

## To-Do

- Move NetBox from my own deployment mechanism to the official NetBox Helm chart.
- Move away from ingress-nginx and implement the Cilium Gateway API for routing traffic into the K8s cluster.
- Add support for multi-node Kubernetes clusters using [kind](`https://kind.sigs.k8s.io/`) as an alternative to single-node minikube clusters.
- Deploy and manage FluxCD with the [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator) instead of the `flux bootstrap` command.

## Warning

**Never commit cleartext API tokens or passwords for cloud services, APIs, or production systems to GitHub. The credentials provided in the dev-cliip repo are local-only and cannot access anything outside your Mac.**

The dev-cliip environment is designed as a playground for development and experimentation. Parts of dev-cliip should **never** be used in production environments without making the necessary adjustments. You must perform thorough due diligence and testing before deploying any component in a production environment.

Specifically, never reuse any component of this project in a real-world environment without:

- Rotating all passwords and tokens.
- Encrypting secrets before storing them in GitHub (or other locations).
- Enabling TLS on all endpoints.
- Implementing proper authentication and authorization.
- Plan for high availability, scalability and disaster recovery scenarios.

## How to start?

Start by forking this project into a **private** repository called `dev-cliip`. Keep it private since you'll be committing an **encrypted** API token to your repo. We will use [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) to encrypt credentials that will be committed to your forked repo.

After that, create a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) (PAT) called `dev-cliip` with the following permissions and grant the PAT access to your `dev-cliip` repository:

- Read and Write access to administration, code, commit statuses, and pull requests.
- Read access to metadata.

This is necessary because FluxCD will use the PAT in a later stage to upload and download files to the `flux` folder in your dev-cliip repository. The PAT will also be used as a part of an automation workflow where files will be commited to your repo.

Clone your forked repository to your Mac and check out the latest tag.

Disable any VPN clients before deploying and using dev-cliip, as VPNs can interfere with local routing on your Mac and cause connectivity issues.

## dev-cliip dependencies

### Ansible installation and experience

For this project I assume you already have Ansible installed on your Mac and that you have experience using Ansible. Although Ansible is not used during the dev-cliip deployment, it is necessary for certain automation workflows that will be covered in this guide. We won't go into how to install and use Ansible on your Mac, as many excellent resources are already available for that topic.

### Arista cEOS lab ARM64 container images

You will have to download the Arista cEOS ARM64 based container image that will be used in Containerlab topologies yourself and store it in a folder on your Mac, preferably in `~/container-images`.

### Visual Studio Code and extensions

To get the most out of dev-cliip, it is recommended to use Visual Studio Code as your editor and install the following extensions:

- Containerlab
- Remote - SSH

### Tools on your Mac (host OS)

- [Homebrew](https://brew.sh/) is used to download necessary tools on our Mac.
- [Lima](https://github.com/lima-vm/lima) is used to run the dev-cliip Debian VM locally on our Mac.
- [kubectl](https://kubernetes.io/docs/reference/kubectl/) is used to interact with the dev-cliip K8s cluster that will run on the dev-cliip VM.
- [Helm](https://github.com/helm/helm) is used to bootstrap the Cilium CNI on the dev-cliip K8s cluster before Flux takes over management of the Cilium HelmRelease.
- [cilium-cli](https://github.com/cilium/cilium-cli) is used to interact with the Cilium CNI on the dev-cliip K8s cluster.
- [Flux CLI](https://github.com/fluxcd/flux2/releases) is used to interact with the Flux controllers on the dev-cliip K8s cluster.
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets) is used to interact with the sealed-secrets controller on the dev-cliip K8s cluster.

### Tools on the dev-cliip VM (guest OS)

- [Docker](https://github.com/docker) is used on the dev-cliip VM to run the minikube cluster and Containerlab components.
- [minikube](https://github.com/kubernetes/minikube) is used to run K8s locally on the dev-cliip VM.
- [Containerlab](https://github.com/srl-labs/containerlab) is used to create container-based networking labs.

### Applications on the dev-cliip K8s cluster

- [Cilium](https://github.com/cilium/cilium) is used as the CNI in the dev-cliip K8s cluster.
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) contains Alertmanager, Prometheus, Prometheus exporters and Grafana in a bundle. Prometheus will be used to collect and store metrics in the Prometheus Time Series Database. Grafana will be used for the visualization of these metrics.
- [prometheus-blackbox-exporter](https://github.com/prometheus/blackbox_exporter) is used for blackbox probing of endpoints over HTTP, HTTPS, DNS, TCP, ICMP and gRPC.
- [NetBox](https://github.com/netbox-community/netbox) is used as the Network Single Source of Truth (NSSoT with IPAM and DCIM).
- [gNMIc](https://github.com/openconfig/gnmic) is used as the gNMI collector for monitoring (network) devices.
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) is used to encrypt Kubernetes secrets so they can be stored in a (public) location like GitHub.

### dev-cliip dependencies installation scripts

To create and use dev-cliip, the tools described above should be installed. In the `scripts/shell` folder, there are multiple shell scripts that automate the installation of all necessary software on both the host and guest operating systems. The scripts only support ARM64 macOS (M-series models) as the host system and an ARM64 Debian 13 Linux VM as the guest operating system.

Unless otherwise specified, all commands in this guide should be executed from the root of the cloned dev-cliip repository.

### dev-cliip creation steps

1. Run the host installation script on your Mac (or install the latest version of the tools by hand):

    ```sh
    chmod +x ./scripts/shell/host-install-dev-cliip.sh
    ./scripts/shell/host-install-dev-cliip.sh
    ```

2. Create the dev-cliip Debian VM with Lima:

    Now that all the necessary software is installed on your Mac, let's create the dev-cliip Debian 13 VM! In the `lima` folder, you'll find the `dev-cliip-debian-13.yaml` Lima config file. Adjust the following components in the config file before continuing:

    - The amount of RAM and CPU, based on your MacBook hardware configuration (my Mac has the M2 Pro SoC and 32GB of memory).
    - The mount paths according to where you cloned your fork of the dev-cliip project and where you stored the Arista cEOS ARM image.

    **Note:** The current paths in the config file are examples, where `USER` corresponds to the output of `echo $USER` on your Mac.

    Create the `dev-cliip-debian-13` VM instance:

    ```sh
    limactl start lima/dev-cliip-debian-13.yaml
    ```

    After the VM is created, add the following lines to the `~/.ssh/config` file on your Mac:

    ```sh
    Host lima-dev-cliip-debian-13
        Include ~/.lima/dev-cliip-debian-13/ssh.config
        LocalForward 8443 192.168.49.2:8443
        LocalForward 8080 192.168.49.2:30010
    ```

    The LocalForward entries enable connectivity from your Mac to endpoints running on the dev-cliip VM over the SSH session. For this to work, no processes on your Mac should already be listening on TCP port 8443 or 8080.

    Now you should be able to SSH into the dev-cliip VM:

    ```sh
    ssh lima-dev-cliip-debian-13
    ```

3. Run the guest installation script:

    After login in to the dev-cliip VM, run the guest installation script on the VM (the dev-cliip repo folder should be mounted in the VM:

    ```sh
    cd ~/dev-cliip
    chmod +x ./scripts/shell/guest-install-dev-cliip.sh
    ./scripts/shell/guest-install-dev-cliip.sh
    ```

    After all the tools have been installed, we can create the minikube dev-cliip K8s cluster!

4. Create dev-cliip K8s cluster on the VM:

    By executing the following command you create a single node K8s cluster called the dev-cliip cluster.

    ```sh
    minikube start --cpus=4 --cni=bridge --memory=no-limit --driver=docker --profile=dev-cliip --static-ip=192.168.49.2
    ```

    When the creation of the cluster is finished, minikube has automatically updated the `~/.kube/config` file on the VM.
    We need to copy the certificates minikube generated from the VM to our Mac so we can authenticate ourselves to the kube-apiserver and use tools like `kubectl` locally.

    To do this perform the following commands on your Mac (not on the VM):

    ```sh
    mkdir -p ~/.kube/lima-dev-cliip

    limactl copy dev-cliip-debian-13:/home/$USER.linux/.minikube/ca.crt ~/.kube/lima-dev-cliip/
    limactl copy dev-cliip-debian-13:/home/$USER.linux/.minikube/profiles/dev-cliip/client.crt ~/.kube/lima-dev-cliip/
    limactl copy dev-cliip-debian-13:/home/$USER.linux/.minikube/profiles/dev-cliip/client.key ~/.kube/lima-dev-cliip/

    kubectl config set-cluster lima-dev-cliip \
      --server=https://localhost:8443 \
      --certificate-authority=$HOME/.kube/lima-dev-cliip/ca.crt
    kubectl config set-credentials lima-dev-cliip \
      --client-certificate=$HOME/.kube/lima-dev-cliip/client.crt \
      --client-key=$HOME/.kube/lima-dev-cliip/client.key
    kubectl config set-context lima-dev-cliip \
      --cluster=lima-dev-cliip \
      --user=lima-dev-cliip \
      --namespace=default
    kubectl config use-context lima-dev-cliip
    ```

    Now we are able to reach the kube-apiserver and check the dev-cliip cluster status.
    All K8s related tools are used locally on your Mac:

    ```sh
    kubectl get pods -A
    kubectl get nodes
    ```

    As you can see, the cluster is ready, but we want to change the default minikube CNI (bridge) to Cilium.

    On your Mac perform the following command from the root of the dev-cliip repo:

    ```sh
    helm install cilium cilium/cilium -f flux/infrastructure/dev-cliip/components/cilium/cilium-helm-values.yaml --version 1.18.2 --namespace kube-system
    ```

    Check the status of Cilium after a minute two:

    ```sh
    cilium status
    ```

    Now we have a K8s cluster running on the dev-cliip VM that is ready to host all the other components that are part of dev-cliip!

5. Bootstrap the dev-cliip K8s cluster with Flux and reconcile the dev-cliip components:

    With a working Kubernetes cluster in place, the next step is to bootstrap it with all the dev-cliip components.
    The FLux bootstrap command generates the Flux manifests and commits them to your Git repository. It will also deploy the Flux components on the dev-cliip cluster.

    You will need the GitHub PAT that you created after forking the dev-cliip project. On your Mac perform the following command (the `OWNER` field should be set to your own GitHub username):

    ```sh
    flux bootstrap github \
      --token-auth \
      --owner=OWNER \
      --repository=dev-cliip \
      --branch=main \
      --path=flux/clusters/dev-cliip \
      --personal
    ```

    After the Flux bootstrap command reports `all components are healthy`, the Flux controllers will automatically start reconciling all the resources in the `flux` folder onto the dev-cliip cluster. This can take 3 to 10 minutes depending on available bandwidth and compute resources available on your dev-cliip VM.

    You can check the progress of the reconciliation of all components with the following command:

    ```sh
    flux get all -A
    ```

    After a few minutes all applications should be running.
    Check this by using this command:

    ```sh
    kubectl get pods -A
    ```

6. Add FQDNs to the `/etc/hosts` file:

    Add the FQDNs to your `/etc/hosts` file on your Mac:

    ```sh
    # dev-cliip
    127.0.0.1 netbox.dev-cliip.test
    127.0.0.1 prometheus.dev-cliip.test
    127.0.0.1 grafana.dev-cliip.test
    127.0.0.1 alertmanager.dev-cliip.test
    ```

7. Check if the applications running on the dev-cliip cluster are reachable:

    On your Mac open a web browser and browse to `http://netbox.dev-cliip.test:8080` or choose a different application from the FQDN list. Applications should be available on TCP port 8080 over HTTP.

    The credentials for logging into the applications are as follows:

    | App | Username | Password |
    |-----------------|:---------------:|----------------:|
    | NetBox | admin  | 9H5vGWdLZvhfSAZEPoouuofe8  |
    | Grafana  | admin  | prom-operator  |
    | Alertmanager  | n.a.  | n.a.  |
    | Prometheus  | n.a.  | n.a.  |

8. Create a Docker image from a cEOS ARM container image:

    Download the latest version of the cEOSarm-lab image and move the file to the local container-images folder on your Mac. The exact path is defined in the Lima VM config file you adjusted in step 2.

    On the VM, perform the following commands (adjust the version to match the cEOS image you are using):

    ```sh
    cd ~/container-images/
    docker import cEOSarm-lab-4.34.3M.tar.tar ceos-arm-lab:4.34.3M
    ```

    Creating the image can take a while. Upon completion, you should see the new image in the list when you run this command:

    ```sh
    docker images
    ```

    You now have the necessary container image available to create a Containerlab topology with Arista EOS switches!

9. Start the Containerlab lab:

    On the VM perform the following commands:

    ```sh
    cd ~/dev-cliip/containerlab/labs/dev-cliip-lab01
    containerlab deploy -t dev-clipp-lab01.clab.yaml
    ```

    After a few seconds, you will have a very simple lab running with two Arista switches interconnected via interfaces Et1 and Et2. You can now log in to SW01 and run some commands. (The default password is `admin`, and there is no `enable` password). Connecting to and running commands on the Containerlab nodes is always performed on the dev-cliip VM:

    ```sh
    ssh admin@clab-dev-cliip-lab01-SW01
    show int status
    show running-config | section management
    ```

    As you can see, Containerlab injected a default configuration that lets you connect to various management and monitoring APIs out of the box after booting. We will use this to our advantage in the next sections.

10. (Optional) Use Visual Studio Code (VSC) to connect to the dev-cliip VM and use the Containerlab VSC extension:

    In this optional step you can use the [Containerlab VSC extension](https://containerlab.dev/manual/vsc-extension/) by setting up a SSH session to the dev-cliip VM from your Mac using [VSC](https://containerlab.dev/manual/vsc-extension/#connect-to-containerlab-host).

## What to do now?

At this moment, all dev-cliip components are running, healthy, and ready to be used for all kinds of network automation, monitoring, and observability experimentation!

In the next sections we will provision NetBox with data using Ansible. We will also enable gNMI monitoring of the two Arista switches in the Containerlab topology, and configure a K8s CronJob in the dev-cliip K8s cluster that dynamically updates the gNMIc targets ConfigMap based on the data in NetBox. But first we need to provision our NSSoT!

## Provisioning NetBox

1. Use Ansible to provision NetBox:

    We will provision NetBox by using the NetBox Ansible collection. This will be accomplished by running two Ansible playbooks that are part of the dev-cliip project. After performing the steps below the data in NetBox will reflect the virtual infrastructure we have running in the dev-cliip-lab01 Containerlab topology!

2. Run provisioning playbooks:

    All commands in this step are executed on your Mac (not on the VM).
    First install the Python requirements in the `requirements.txt` file on your Mac (use your preferred way).
    Then install the NetBox Ansible collection:

    ```sh
    cd ansible
    ansible-galaxy install -r collections/requirements.yaml
    ```

    The output of the Ansible tasks show what objects are being created when running the following command:

    ```sh
    ansible-playbook -i inventories/dev-cliip-provision-netbox/inventory.yaml playbooks/netbox_provision_dcim.yaml
    ```

    We need to create the VRFs in NetBox first before we can continue with provisioning the actual devices:

    ```sh
    ansible-playbook -i inventories/dev-cliip-provision-netbox/inventory.yaml playbooks/netbox_provision_ipam.yaml --tags netbox_vrf
    ```

    Then run:

    ```sh
    ansible-playbook -i inventories/dev-cliip-provision-netbox/inventory.yaml playbooks/netbox_provision_dcim.yaml --tags=netbox_devices,netbox_device,netbox_device_interface,netbox_cables,netbox_cable
    ```

    Finally run:

    ```sh
    ansible-playbook -i inventories/dev-cliip-provision-netbox/inventory.yaml playbooks/netbox_provision_ipam.yaml
    ```

    Checkout the [devices page in your NetBox instance](http://netbox.dev-cliip.test:8080/dcim/devices/) and enjoy the feeling of not having used the GUI to provision all this data! Also pay attention to the custom field that is visible when you view SW01's device page. The `Monitored with` field states that the switch is monitored with gNMIc. Wouldn't it be nice if the gNMIc collector would automatically start monitoring any new Arista device added to NetBox, so we only have to provision it in NetBox with the right values? That is exactly what we are going to do in the next section.

## Enable gNMIc monitoring with dynamic target file creation

In Visual Studio Code on your Mac check out the files in this folder of the dev-cliip project `flux/applications/base/network-monitoring`.

Here you see all the K8s manifests that make sure that the `network-monitoring` namespace was created on the dev-cliip cluster and that the gNMIc collector is running in the namespace waiting to do some gNMI monitoring!

### gNMIC collector configuration

In the `gnmic-config-files` folder`gnmic-config-sealedSecret.yaml` file you can see the config that is mounted into the gNMIc container during startup.

Run this command to see the running gNMIc pod and to see the logging that it produces:

```sh
kubectl get pods -n network-monitoring
kubectl logs -n network-monitoring gnmic-0
```

As you can see in the logging gNMIc is not doing a lot because the `gnmic-targets-configMap.yaml` file is empty and gNMIc will thus not monitor any devices. We will need to populate that ConfigMap with the devices that are running in our `dev-clipp-lab01` Containerlab topology.

## Dynamically populate gNMIc targets ConfigMap

In the `flux/applications/base/network-monitoring/gnmic/jobs` folder you will find three manifest. The `create-gnmic-target-file-configMap.yaml` file contains a Jinja2 template and a Python script that will be mounted into a Python container that is described in the `create-gnmic-target-file-cronJob.yaml`. The `create-gnmic-target-file-credentials-sealedSecret.yaml` contains the secrets we need to authenticate to the NetBox and GitHub API and those secrets will also be available as environment variables in the Python container.

In the following steps we will make sure that:

- The K8s manifests in the `jobs` folder will contain the necessary information for the K8s CronJob to work.
- Flux will reconcile the manifest on the dev-cliip cluster.
- The CronJob will run successfully and fetch the devices from NetBox, render the template and commit the gNMIc targets configmap to the `flux/applications/base/network-monitoring/gnmic/gnmic-config-files/gnmic-targets-configMap.yaml` file on the `main` branch.
- Flux will reconcile the updated ConfigMap to the dev-cliip cluster and the gNMIc collector will start to monitor both switches that are running in our Containerlab topology.

Let's go:

1. Start by adding your PAT and GitHub username (both in base64 format) to the `GITHUB_PAT` key and `GITHUB_REPO_OWNER` respectively in the `create-gnmic-target-file-credentials-sealedSecret.yaml` file in the `jobs` folder.
2. Then uncomment the three commented lines in the `flux/applications/base/network-monitoring/kustomization.yaml` file.
3. Transform the `create-gnmic-target-file-credentials-sealedSecret.yaml` Secret into a SealedSecret so you can safely upload this data to your private dev-cliip GitHub repo:

    On your Mac in the root of the dev-cliip folder run:

    ```sh
    cat flux/applications/base/network-monitoring/gnmic/jobs/create-gnmic-target-file-credentials-sealedSecret.yaml | kubeseal --controller-namespace sealed-secrets --controller-name sealed-secrets -o yaml | pbcopy
    ```

    The `pbcopy` command caused the output to be on your clipboard. Now remove all lines in the file (`create-gnmic-target-file-credentials-sealedSecret.yaml`) you just kubesealed and paste the contents from the clipboard in that file. You end up with the file looking something like this:

    ```yaml
    ---
    apiVersion: bitnami.com/v1alpha1
    kind: SealedSecret
    metadata:
      name: create-gnmic-target-file-credentials
      namespace: network-monitoring
    spec:
      encryptedData:
        GITHUB_PAT: encrypted
        NETBOX_API_TOKEN: encrypted
        NETBOX_URL: encrypted
        GITHUB_REPO_NAME: encrypted
        GITHUB_REPO_OWNER: encrypted
      template:
        metadata:
          name: create-gnmic-target-file-credentials
          namespace: network-monitoring
        type: Opaque
    ```

    **Note:** this SealedSecret can only be unsealed by the Sealed Secrets controller with the private key it was sealed with. You will have to kubeseal the original K8s Secret again when you delete the dev-cliip VM and deploy dev-cliip from the start.

4. Commit the changes to the `main` branch of your dev-cliip repo.

5. Trigger a Flux reconciliation of the `network-monitoring` Kustomization (this command will fetch the latest version of the `main` branch of your dev-cliip repo and the Flux controllers will update all K8s manifests):

    ```sh
    flux reconcile kustomization network-monitoring --with-source
    ```

    After the reconciliation check if the ConfigMap, Secret, and CronJob are now available in the network-monitoring namespace:

    ```sh
    kubectl -n network-monitoring get configmaps
    kubectl -n network-monitoring get secrets
    kubectl -n network-monitoring get cronjobs
    ```

    The SealedSecret you just committed to the main branch was `unsealed` in the dev-cliip cluster by the Sealed Secrets controller running in the sealed-secrets namespace. This ensures that your credentials are only available in unencrypted form on your local dev-cliip cluster.

6. Manually trigger a K8s Job based on the CronJob manifest that was just reconciled on the dev-cliip cluster:

    ```sh
    kubectl -n network-monitoring create job --from=cronjob/create-gnmic-target-file create-gnmic-target-file-dev-cliip-guide
    ```

7. Check the logs from the Job pod. The pod name should start with `create-gnmic-target-file-dev-cliip-guide` and has a specific ID suffix:

    ```sh
    kubectl -n network-monitoring logs create-gnmic-target-file-dev-cliip-guide
    ```

    The logs should resemble something like:

    ```text
    2025-10-08 15:49:26,864 - INFO - Checking if file exists on branch 'main': flux/applications/base/network-monitoring/gnmic/   gnmic-config-files/gnmic-targets-configMap.yaml
    2025-10-08 15:49:27,563 - INFO - File exists, SHA: f6b2d3ed47da5ddb844738a9868818ff420cfd5d
    2025-10-08 15:49:27,563 - INFO - Uploading file to GitHub branch 'main': flux/applications/base/network-monitoring/gnmic/ gnmic-config-files/gnmic-targets-configMap.yaml
    2025-10-08 15:49:28,247 - INFO - Successfully uploaded file to GitHub: flux/applications/base/network-monitoring/gnmic/ gnmic-config-files/gnmic-targets-configMap.yaml
    ```

    Now the `gnmic-targets` ConfigMap is dynamically created based on data from NetBox and commited to the dev-cliip repo!
    You can check if this actually happened in GitHub or fetch the updated file locally and check what has actually changed.

8. Trigger a Flux reconciliation of the `network-monitoring` Kustomization again:

    ```sh
    flux reconcile kustomization network-monitoring --with-source
    ```

    Now the `gnmic-targets` ConfigMap is reconciled in the network-monitoring namespace and ready for the gNMIc collector to use:

    ```sh
    kubectl -n network-monitoring get configmap gnmic-targets -o yaml
    ```

9. Restart the gNMIc collector and check the logs again:

    ```sh
    kubectl -n network-monitoring rollout restart statefulset gnmic
    kubectl logs -n network-monitoring gnmic-0
    ```

    The gNMIc container will mount the `gnmic-targets` ConfigMap and initiate a gNMI session to both targets.
    gNMIc will subscribe to the `/interfaces/interface` path and the switches will update the counters every 5 seconds.
    Prometheus is configured to scrape the `/metrics` endpoint that is exposed by the gNMIc container every 5 seconds also:

    You can check the ServiceMonitor that instructs Prometheus to scrape the gNMIc pod by using this command on your Mac:

    ```sh
    kubectl -n network-monitoring get servicemonitors.monitoring.coreos.com gnmic-gnmi-network-monitoring -o yaml
    ```

10. Check the collected metrics in Prometheus:

    On your Mac open this [Prometheus URL](http://prometheus.dev-cliip.test:8080/query?g0.expr=gnmic_interfaces_interface_state_counters_out_octets&g0.show_tree=0&g0.tab=graph&g0.range_input=15m&g0.res_type=auto&g0.res_density=medium&g0.display_mode=lines&g0.show_exemplars=0).

    You should see a graph that shows the values for the `gnmic_interfaces_interface_state_counters_out_octets` metric.
    The two lines you see represent the increasing number of outbound octets on the `Management0` interface of both switches, and it is updated by the switch every 5 seconds!

    If you want to see what other metrics are collected by only subscribing to the `/interfaces/interface` path, start typing `gnmic` in the metric browser and it will show all gNMIc metrics that are available to check.

Now we have all of this in place and the gNMIc targets ConfigMap is updated dynamically (every day at 14:00 or when you trigger a Job like you did in step 6) with data from the NSSoT, try adding a new Arista EOS device to NetBox and see if it eventually ends up in the logs of the gNMIc pod!

## What to do next?

Delete the dev-cliip VM and do it all over:

```sh
limactl stop dev-cliip-debian-13
limactl delete dev-cliip-debian-13
```

Now that you can deploy dev-cliip from scratch, try the following:

- Adding more automation workflows.
- Add new applications to the dev-cliip cluster with the help of FluxCD (for example [cert-manager](https://cert-manager.io/) and enable TLS on the ingresses).
- Experiment with the gNMI protocol and all settings gNMIc offers (maybe add extra paths to subscribe to on the Arista switches).
- Create fancy [Grafana](http://grafana.dev-cliip.test:8080/) dashboards.
- Create a new Containerlab topology (with multiple vendors) and monitor those devices with gNMI to.
- Create new Ansible playbooks and roles to automate things.
- Incorporate the [Arista AVD project](https://avd.arista.com/) into dev-cliip and use NetBox as the NSSoT.
- Whatever else you can come up with!
