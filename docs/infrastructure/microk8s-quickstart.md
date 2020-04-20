# Creating a MicroK8s cluster

[MicroK8s](https://microk8s.io/) is a lightweight, fully conformant, single-package Kubernetes developed by Canonical. The project is [publicly available on GitHub](https://github.com/ubuntu/microk8s).

Follow the instructions below to set up a MicroK8s instance from scratch, including all the necessary dependencies and configurations.

As part of this process, the Helm client (`helm`) and the Helm server (`tiller`) will be installed on the MicroK8s instance:

-   `helm` is the command-line client responsible for resolving the configuration of the chart to be installed and issuing the correct install commands onto the Helm server.
-   `tiller` is the in-cluster server responsible for receiving the install commands issued by the Helm client and managing the lifecycle of the components that have been installed.

## 1. Prepare your environment

Prepare your environment to set up the MicroK8s instance.

You will need a machine running [Ubuntu Server 18.04 LTS](https://ubuntu.com/download/server) that:

-   Is correctly provisioned with the resources described for MicroK8s in the [system requirements](../requirements.md#kubernetes-or-microK8s-cluster-setup)
-   Is able to establish a connection to the PostgreSQL instance described in the [system requirements](../requirements.md#postgresql-server-setup)

The next steps assume that you are starting from a clean install of Ubuntu Server and require that you run commands on a local or remote command line session on the machine.

## 2. Installing MicroK8s

Install MicroK8s on the machine:

1.  Make sure that the package `nfs-common` is installed:

    ```bash
    sudo apt update && sudo apt install nfs-common -y
    ```

2.  Install MicroK8s from the `1.15/stable` channel:

    ```bash
    sudo snap install microk8s --classic --channel=1.15/stable
    sudo usermod -a -G microk8s $USER
    sudo su - $USER
    ```

3.  Check that MicroK8s is running:

    ```bash
    $ microk8s.status --wait-ready
    microk8s is running
    addons:
    knative: disabled
    jaeger: disabled
    fluentd: disabled
    gpu: disabled
    cilium: disabled
    storage: disabled
    registry: disabled
    rbac: disabled
    ingress: disabled
    dns: disabled
    metrics-server: disabled
    linkerd: disabled
    prometheus: disabled
    istio: disabled
    dashboard: disabled
    ```

## 3. Configuring MicroK8s

Now that MicroK8s is running on the machine we can proceed to enabling the necessary plugins and installing the Helm client and server:

1.  Enable the following plugins on MicroK8s:

    ```bash
    sudo mkdir -p /var/snap/microk8s/current/args
    sudo echo "--allow-privileged=true" >> /var/snap/microk8s/current/args/kube-apiserver
    microk8s.status --wait-ready
    microk8s.enable dns
    microk8s.enable storage
    microk8s.enable ingress
    microk8s.status --wait-ready
    microk8s.stop
    microk8s.start
    microk8s.status --wait-ready
    ```

2.  Install version v2.16.3 of the Helm client:

    ```bash
    sudo snap install helm --classic --channel=2.16/stable
    ```

3.  Install the Helm server:

    ```bash
    microk8s.kubectl create serviceaccount --namespace kube-system tiller
    microk8s.kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    helm init --service-account tiller
    ```

4.  The plugins are now enabled and the MicroK8s instance bootstrapped. However, we must wait for some MicroK8s pods to be ready, as failing to do so can result in the pods entering a `CrashLoopBackoff` state:

    ```bash
    microk8s.kubectl wait -n kube-system --for=condition=Ready pod -l k8s-app=kube-dns
    microk8s.kubectl wait -n kube-system --for=condition=Ready pod -l k8s-app=hostpath-provisioner
    # If the following command fails, you probably installed the wrong microk8s version
    microk8s.kubectl wait -n default --for=condition=Ready pod -l name=nginx-ingress-microk8s
    microk8s.kubectl -n kube-system wait --for=condition=Ready pod -l name=tiller
    ```

    After these commands return successfully we have ensured that DNS, HTTP, and NGINX Ingress are enabled and working properly inside the MicroK8s instance.

## Notes on installing Codacy

You can now follow the generic [Codacy installation instructions](../index.md#2-installing-codacy) but please note the following:

-   You must execute all `kubectl` commands as `microk8s.kubectl` commands instead.

    To simplify this, we suggest that you create an alias so that you can run the commands directly as provided on the instructions:

    ```bash
    alias kubectl=microk8s.kubectl
    ```

-   When running the `helm upgrade` command that installs the Codacy chart you must append the file `values-microk8s.yaml` that downsizes some component limits, making it easier to fit Codacy in the lightweight MicroK8s solution.

    You can download the file `values-microk8s.yaml` by running:

    ```bash
    wget https://raw.githubusercontent.com/codacy/chart/master/codacy/values-microk8s.yaml
    ```