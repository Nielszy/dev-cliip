# avd_cicd

This folder contains a demo NetDevOps CI/CD pipeline for an Arista [AVD](https://avd.arista.com/) single data center layer 3 leaf-spine (L3LS) fabric. The pipeline runs on GitLab CI using the optional containerlab GitLab Runner in the dev-cliip Kubernetes cluster. It builds the intended configuration with AVD, deploys a digital twin of the fabric with Containerlab, and validates that twin with [ANTA](https://anta.arista.com/).

## Folder structure

| Path | Description |
| --- | --- |
| `.gitlab-ci.yml` | GitLab CI pipeline definition. |
| `.yamllint.yaml` | yamllint rules used in the `lint` stage. |
| `.ansible-lint.yaml` | ansible-lint rules used in the `lint` stage. |
| `single_dc_l3ls/` | AVD project for the single DC L3LS fabric (inventory, `group_vars`, `host_vars` and playbooks). |
| `single_dc_l3ls/build.yml` | Generates structured configs, device configs and fabric documentation (`eos_designs` and `eos_cli_config_gen`). |
| `single_dc_l3ls/simulate.yml` | Generates the Containerlab topology for the digital twin with [eos_designs_to_containerlab](https://github.com/arista-netdevops-community/eos_designs_to_containerlab). |
| `single_dc_l3ls/deploy_eapi.yml` | Deploys the intended configuration to the devices through eAPI. |
| `single_dc_l3ls/deploy_cv.yml` | Deploys configurations and tags to Arista CloudVision (`cv_deploy`). |
| `single_dc_l3ls/validate.yml` | Validates the fabric with ANTA (`anta_runner`). |

## Pipeline overview

All jobs run in the `ghcr.io/nielszy/netdevops-ee` execution environment image on a runner with the `avd` tag.

| Stage | Job | When it runs |
| --- | --- | --- |
| `lint` | Lint the YAML files (yamllint) and the Ansible files (ansible-lint). | Automatically on feature branch pushes, merge requests and web triggers. |
| `build` | Run `build.yml` and commit any changes in `intended/` and `documentation/` back to the branch. | Manually on feature branches and merge requests. |
| `digital-twin` | Deploy the Containerlab digital twin, push the configs through eAPI, run the ANTA tests, commit the results in `anta/`, and destroy the lab. | Manually on feature branches and merge requests. |
| `update` | Update NetBox (placeholder). | Manually on `main`. |
| `deploy` | Push the configs to CloudVision (`deploy_cv.yml`), or straight to production through eAPI (placeholder). | Manually on `main`. |
| `validate` | Run the ANTA tests against production (placeholder). | Manually on `main`. |

Commits made by the pipeline include `[skip ci]` so that they don't start a new pipeline.

## Prerequisites

- A running dev-cliip environment (see the [main README](../README.md)).
- The optional containerlab GitLab Runner is enabled and registered to your GitLab project with the `avd` tag (see the **Optional: GitLab Runner** section in the main README).
- The contents of this folder have been pushed to a GitLab project.
- The Arista cEOS ARM64 lab image is available in the minikube registry (see below).
- For the CloudVision deploy job: fill in `ansible_host` and `ansible_password` (token) for the `cloudvision` host in `single_dc_l3ls/inventory.yml`. Never commit real credentials in cleartext; use GitLab CI/CD variables or Ansible Vault instead.

## Host the cEOS ARM image in the minikube registry

The digital twin job pulls the cEOS image from `registry.kube-system.svc.cluster.local:80/ceos-arm-lab:4.36.3.2M` (set through `sim_ceos_version` in `single_dc_l3ls/inventory.yml`). The steps below put the image in that registry.

The commands run on two machines:

| Machine | Prompt looks like | How to get there |
| --- | --- | --- |
| Your Mac (host) | `user@your-mac ~ %` | Open a terminal. |
| Lima VM (guest) | `user@lima-dev-cliip-debian-13:~$` | Run `limactl shell dev-cliip-debian-13` on your Mac, or connect with VS Code Remote - SSH. |

Don't run the commands inside the minikube node (`minikube ssh`). The node has no Docker daemon, so `docker` commands fail there.

### 1. Copy the image to the shared folder (Mac)

Download the cEOSarm-lab image from arista.com and move it to `~/container-images` on your Mac. The Lima VM mounts this folder.

### 2. Enable the registry and import the image (Lima VM)

```sh
minikube addons enable registry -p dev-cliip
cd ~/container-images/
docker import cEOSarm-lab-4.36.3.2M.tar.tar ceos-arm-lab:4.36.3.2M
```

If `minikube` fails with `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`, your session doesn't have the `docker` group yet. Run `newgrp docker`, or restart the VM from your Mac with `limactl stop dev-cliip-debian-13 && limactl start dev-cliip-debian-13`.

### 3. Push the image to the registry (Lima VM)

`kubectl` isn't installed in the Lima VM, so use `minikube kubectl --` to forward a local port to the registry service. Use `127.0.0.1` rather than `localhost`: Docker only allows plain HTTP for registries on `127.0.0.0/8`, and `localhost` can resolve to the IPv6 address `::1`.

```sh
minikube -p dev-cliip kubectl -- port-forward -n kube-system svc/registry 5000:80 &
sleep 3
docker tag ceos-arm-lab:4.36.3.2M 127.0.0.1:5000/ceos-arm-lab:4.36.3.2M
docker push 127.0.0.1:5000/ceos-arm-lab:4.36.3.2M
```

The first run of `minikube kubectl` may download a kubectl binary. If the push fails with `connection refused`, the port-forward isn't ready yet. Wait a few seconds and run `docker push` again.

### 4. Verify and clean up (Lima VM)

```sh
curl http://127.0.0.1:5000/v2/_catalog       # should list ceos-arm-lab
kill %1                                      # stop the port-forward
```

If you use another cEOS version, update the image tag in these commands and the `sim_ceos_version` variable in `single_dc_l3ls/inventory.yml`.

## Typical workflow

1. Create a feature branch and change the fabric data model in `single_dc_l3ls/group_vars` or `single_dc_l3ls/host_vars`.
2. Push the branch or open a merge request. The lint jobs run automatically.
3. Start the `build` job manually. It commits the regenerated configs and documentation to your branch.
4. Start the `digital-twin` job manually. It commits the ANTA results to `single_dc_l3ls/anta/` on your branch.
5. Review the generated configs, documentation and ANTA results in the merge request, then merge to `main`.
6. On `main`, start the `update`, `deploy` and `validate` jobs manually.

## Run locally

You can also run the playbooks from the `single_dc_l3ls` folder, as long as the `arista.avd` collection is installed:

```sh
cd single_dc_l3ls
ansible-playbook build.yml
```
