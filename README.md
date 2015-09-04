# CoreOS

Create a local CoreOS virtual machine using the VirtualBox software hypervisor.
After setup is complete you will have a single CoreOS virtual machine running on your local machine.

## Get started

1) Install dependencies

* [VirtualBox][virtualbox] 4.3.10 or greater.
* [Vagrant][vagrant] 1.6 or greater.

2) Clone this project and get it running!

```
git clone https://github.com/mattma/coreos-distro.git
cd coreos-distro
```

3) Startup and SSH

There are two "providers" for Vagrant with slightly different instructions.
Follow one of the following two options:

**VirtualBox Provider**

The VirtualBox provider is the default Vagrant provider. Use this if you are unsure.

```
vagrant up
vagrant ssh
```

**VMware Provider**

The VMware provider is a commercial addon from Hashicorp that offers better stability and speed.
If you use this provider follow these instructions.

VMware Fusion:
```
vagrant up --provider vmware_fusion
vagrant ssh
```

VMware Workstation:
```
vagrant up --provider vmware_workstation
vagrant ssh
```

`vagrant up` triggers vagrant to download the CoreOS image (if necessary) and (re)launch the instance

`vagrant ssh` connects you to the virtual machine.

Configuration is stored in the directory so you can always return to this machine by executing `vagrant ssh` from the directory where the Vagrantfile was located.

4) Get started [using CoreOS][using-coreos]

[virtualbox]: https://www.virtualbox.org/
[vagrant]: https://www.vagrantup.com/downloads.html
[using-coreos]: http://coreos.com/docs/using-coreos/

#### Shared Folder Setup

There is optional shared folder setup.
You can try it out by adding a section to your Vagrantfile like this.

```
config.vm.network "private_network", ip: "172.17.8.150"
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

After a 'vagrant reload' you will be prompted for your local machine password.

#### Provisioning with user-data

The Vagrantfile will provision your CoreOS VM(s) with [coreos-cloudinit][coreos-cloudinit] if a `user-data` file is found in the project directory.
coreos-cloudinit simplifies the provisioning process through the use of a script or cloud-config document.

To get started, copy `user-data.sample` to `user-data` and make any necessary modifications.
Check out the [coreos-cloudinit documentation][coreos-cloudinit] to learn about the available features.

[coreos-cloudinit]: https://github.com/coreos/coreos-cloudinit

#### Configuration

The Vagrantfile will parse a `config.rb` file containing a set of options used to configure your CoreOS cluster.
See `config.rb.sample` for more information.

## Cluster Setup

Launching a CoreOS cluster on Vagrant is as simple as configuring `$num_instances` in a `config.rb` file to 3 (or more!) and running `vagrant up`.
Make sure you provide a fresh discovery URL in your `user-data` if you wish to bootstrap etcd in your cluster.

## New Box Versions

CoreOS is a rolling release distribution and versions that are out of date will automatically update.
If you want to start from the most up to date version you will need to make sure that you have the latest box file of CoreOS.
Simply remove the old box file and vagrant will download the latest one the next time you `vagrant up`.

```
vagrant box remove coreos --provider vmware_fusion
vagrant box remove coreos --provider vmware_workstation
vagrant box remove coreos --provider virtualbox
```

## Docker Forwarding

By setting the `$expose_docker_tcp` configuration value you can forward a local TCP port to docker on
each CoreOS machine that you launch. The first machine will be available on the port that you specify
and each additional machine will increment the port by 1.

Follow the [Enable Remote API instructions][coreos-enabling-port-forwarding] to get the CoreOS VM setup to work with port forwarding.

[coreos-enabling-port-forwarding]: https://coreos.com/docs/launching-containers/building/customizing-docker/#enable-the-remote-api-on-a-new-socket

Then you can then use the `docker` command from your local shell by setting `DOCKER_HOST`:

    export DOCKER_HOST=tcp://localhost:2375

## Quick Start Guide

1. Generate Token and remember it

```
TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)

echo $TOKEN
```

2. Genereate Certs and Keys

```bash
./setup/utils/certs.sh
```

3. Generate Certs and Keys

Replace the `TOKEN` value with value from step 1. and update the environment variable values as needed.

```bash
./setup/utils/kube-config.sh
```

4. Modify values in `cloud-init/master-data`

    - modify Environment variables in `/etc/sysconfig/kubernetes-config`
    - copy/paste certs from `setup/tmp/kubernetes/ca.crt` to `/srv/kubernetes/ca.crt`
    - copy/paste server certs from `setup/tmp/kubernetes/server.crt` to `/srv/kubernetes/server.crt`
    - copy/paste keys from `setup/tmp/kubernetes/server.keys` to `/srv/kubernetes/server.keys`
    - use generated token and username to replace values in `/srv/kubernetes/tokens.csv`

```bash
cat ./setup/tmp/kubernetes/ca.crt
cat ./setup/tmp/kubernetes/server.crt
cat ./setup/tmp/kubernetes/server.key

echo $TOKEN
```

5. Spin up Master Node

```bash
ROLE=master IP=172.17.8.100 vagrant up
```

6. Modify values in `cloud-init/node-data`

- update values in *etcd2.initial-cluster* field

```bash
ROLE=master vagrant ssh -c 'cat /etc/machine-id'

cat ~/.kube/config
```

    - copy/paste server kubeconfig from `~/.kube/config` to `/var/lib/kubelet/kubeconfig`
    - copy/paste server kubeconfig from `~/.kube/config` to `/var/lib/kube-proxy/kubeconfig`

7. Spin up Nodes

```bash
IP=172.17.8.101 NUM=1 vagrant up
IP=172.17.8.102 NUM=2 vagrant up
```

8. Setup environment variables

```bash
./setup/utils/init-env-bin.sh
```

Copy and paste *one-liner* or *longer-format* of environment variables.

9. Bring up the cluster

```bash
./setup/utils/kube-up.sh
```

10. Start dns service. SkyDns controller and service

```bash
kubectl create -f setup/dns/dns-controller.yaml
kubectl create -f setup/dns/dns-service.yaml
```

## TL; DR Start Guide

**Master machine**

```bash
# Start master machine
ROLE=master IP=172.17.8.100 vagrant up

INITIAL_CLUSTER_ID=$(ROLE=master vagrant ssh -c 'cat /etc/machine-id')

# open `setup/cloud-init/node-data` file to replace the value in `coreos/etcd2/initial-cluster`. ex:
initial-cluster: "${INITIAL_CLUSTER_ID}=http://${MASTER_IP}:2380"

# Actually value is being saved at `/etc/systemd/system/etcd2.service.d/initial-cluster.conf`
```

Find more [details](./docs/start-master-and-node-machine.md)

**Need to follow [setup-security-models.md](./docs/setup-security-models.md) guide to setup `ca.crt`, `token`, etc**


**Node machine**

```bash
IP=172.17.8.101 NUM=1 vagrant up
IP=172.17.8.102 NUM=2 vagrant up
```

Find more [details](./docs/start-master-and-node-machine.md)

**Need to follow [setup-security-models.md](./docs/setup-security-models.md) guide to setup `kubeconfig` on each node**


**Install `etcdctl` `fleetctl` `kubectl` on host machine**

```bash
./setup/utils/init-env-bin.sh
# Then copy and paste environment variable into the shell window
```

Find more [details](./docs/setup-environment-and-binary.md)


**Test cluster setup**

```bash
fleetctl list-machines

# Validating your cluster
# E.G: 23ddf77271a20473: name=9d793d4a68b8422782f3f582cc3ed0d6 peerURLs=http://172.17.8.100:2380 clientURLs=http://172.17.8.100:2379
etcdctl member list

# member 23ddf77271a20473 is healthy
etcdctl cluster-health
etcdctl ls /

# set value on one node, get value on another node
etcdctl set foo 'bar'
etcdctl get foo
```

**Initialize Kubernetes Control Plane**

```bash
fleetctl start units/kube-apiserver.service
# check the cluster info
kubectl cluster-info

# Wait for `kube-apiserver.service` fully up and running
fleetctl start units/kube-controller-manager.service
fleetctl start units/kube-scheduler.service
```

Deploy SkyDNS.

```bash
# start dns service. SkyDns
kubectl create -f setup/dns/dns-controller.yaml
kubectl create -f setup/dns/dns-service.yaml
```


**Initialize Kubernetes Node worker**

```bash
fleetctl start units/flanneld.service
fleetctl start units/docker.service

fleetctl start units/kube-proxy.service
fleetctl start units/kube-kubelet.service
```


**Docker containers and images GC**

Rule 1: Containers that exited more than an hour ago are removed.
Rule 2: Images that don't belong to any remaining container after that are removed.

```bash
fleetctl submit units/docker-gc.service
fleetctl start docker-gc

# after it started, it will be in `inactive` state and `SUB=dead`
# it needs to be unloaded from the current `fleetctl list-units`
fleetctl unload docker-gc
# run `fleetctl list-unit-files` should still contain `docker-gc.service`
fleetctl start docker-gc
```


**Warning: Cleanup and Reset cluster**

```bash
./setup/cleanup
```

**[Awesome Docs on Systemd](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files)**
**[Write Systemd unit files](http://fedoraproject.org/wiki/Packaging%3aSystemd#Unit_Files)**
