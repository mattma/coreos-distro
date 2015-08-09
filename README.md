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

## Kick start master

Machine does not bootstrap etcd cluster automatically because each machine doesn't know the address of its peers. You need to set correct [ETCD_INITIAL_CLUSTER](https://github.com/coreos/etcd/blob/master/Documentation/configuration.md#-initial-cluster) value manually to help etcd cluster bootstrap, and enable etcd2.service to auto start.

**Single master for etcd cluster**

```bash
# login system as root
sudo su

# get local MachineID, which is used as etcd name
MachineID=`cat /etc/machine-id`

# get AdvertisePeerURL in local etcd2.service
AdvertisePeerURL=`systemctl cat etcd2 | grep ETCD_INITIAL_ADVERTISE_PEER_URLS | sed 's/[="]/ /g' | awk '{print $3}'`

# make a folder to contain etcd2.service configuration
mkdir -p /etc/systemd/system/etcd2.service.d

# create `initial-cluster.conf` file to contain etcd cluster info
echo "[Service]
Environment=\"ETCD_INITIAL_CLUSTER=${MachineID}=${AdvertisePeerURL}\"
"> /etc/systemd/system/etcd2.service.d/initial-cluster.conf

# systemd reload to reload the new configuration
systemctl daemon-reload
# activate etcd2 service
systemctl enable etcd2
systemctl start etcd2

# Debuging
systemctl cat etcd2

# ensure etcd2 service is running
systemctl status etcd2
journalctl -u etcd2

# logout root user
exit
```

**3 masters for etcd cluster**

1. Find out MachineID and AdvertisePeerURL of all 3 masters

2. Build a ETCD_INITIAL_CLUSTER string (`${MachineID_1}=${AdvertisePeerURL_1},${MachineID_2}=${AdvertisePeerURL_2},${MachineID_3}=${AdvertisePeerURL_3}`) that contains all 3 masters

3. Set `ETCD_INITIAL_CLUSTER` in each machine as we do for one master case

4. Enable etcd2 service in each machine as we do for one master case

**Instruction to start master etcd**

```bash
ROLE=master IP=172.17.8.100 vagrant up
# if everything is ok, machine name: kube-master should be running
ROLE=master vagrant status
# login kube-master machine via ssh
ROLE=master vagrant ssh

ROLE=master vagrant destroy -f
```

## Kick start node

You need to set the correct initial cluster value in `user-data` before bootstrapping. The value is the same as the one that is set in master machine. Follow the example below:

```bash
# ssh into Master etcd machine, copy the value of `ETCD_INITIAL_CLUSTER`
cat /etc/systemd/system/etcd2.service.d/initial-cluster.conf

# ex: ETCD_INITIAL_CLUSTER=e0100b6a52d049aeacf52b529d13d006=http://172.17.8.101:2380

# open `setup/cloud-init/node-data` file to replace the value in `coreos/etcd2/initial-cluster`. ex:
initial-cluster: "e0100b6a52d049aeacf52b529d13d006=http://172.17.8.101:2380"
```

Once setup the initial cluster value to point to master etcd, then start a new node to join the etcd cluster

```bash
IP=172.17.8.101 NUM=1 vagrant up
# if everything is ok, machine name: kube-node-01 should be running
IP=172.17.8.101 NUM=1 vagrant status
# login kube-node-01 machine via ssh
IP=172.17.8.101 NUM=1 vagrant ssh
# if do not use it anymore, simply remove the machine
IP=172.17.8.101 NUM=1 vagrant destroy -f
```

Start a second node to join the etcd cluster, so it could perform `etcdctl` command


```bash
IP=172.17.8.102 NUM=2 vagrant up
# if everything is ok, machine name: kube-node-01 should be running
IP=172.17.8.102 NUM=2 vagrant status
# login kube-node-01 machine via ssh
IP=172.17.8.102 NUM=2 vagrant ssh

IP=172.17.8.102 NUM=2 vagrant destroy -f
```

## Etcdctl installation and configuration

**[Installation](https://github.com/coreos/etcd/releases)**

```bash
curl -L  https://github.com/coreos/etcd/releases/download/v2.1.1/etcd-v2.1.1-darwin-amd64.zip -o etcd-v2.1.1-darwin-amd64.zip
unzip etcd-v2.1.1-darwin-amd64.zip
cd etcd-v2.1.1-darwin-amd64
mv ./etcd-v2.1.1-darwin-amd64/etcdctl /usr/local/bin/etcdctl
```

**Running `etcdctl` from external host**

```bash
export ETCDCTL_PEERS=http://172.17.8.100:4001
# list all directory in the current Etcd cluster
etcdctl ls /
```

## Fleet installation and configuration

**Running `fleetctl` from external host**

1. [download `fleet` binary](https://github.com/coreos/fleet/releases). make sure you download the version that matches the version of fleet running on the CoreOS cluster.

2. SSH access for a user to at least one host in the cluster

3. ssh-agent running on a user’s machine with the necessary identity

In order to satisfy #2 and #3 above, i added following to `.ssh/config` on the separate machine where I am running `fleetctl`. Vagrant `insecure_private_key` is available in `~/.vagrant.d`, which i have copied to shared directory `/vagrant`.

```bash
# ~/.ssh/config
Host core-01
 User core
 HostName 172.17.8.100
 IdentityFile ~/.vagrant.d/insecure_private_key
```

4. Once the fleetctl binary is installed and communication is established, run following command. required.

```bash
rm -rf ~/.fleetctl/known_hosts
vi ~/.ssh/config  #update the HOST name to match $instance_name_prefix in vagrantfile
rm ~/.vagrant.d/insecure_private_key

vagrant up

# It doesn’t matter which instance you use as the other end of your SSH tunnel,
export FLEETCTL_TUNNEL=172.17.8.100
ssh-add  ~/.vagrant.d/insecure_private_key
fleetctl list-machines
```

**After reload provision or new setup**

```bash
rm -rf ~/.fleetctl/known_hosts
ssh-add  ~/.vagrant.d/insecure_private_key
export FLEETCTL_TUNNEL=172.17.8.100
fleetctl list-machines
```

**Using `fleetctl` to deploy unit-files**

```bash
cd units
# Submit the “kubernetes apiserver” to CoreOS cluster
fleetctl submit kube-apiserver.service

# Start the service
fleetctl start kube-apiserver.service

# Check status
fleetctl list-units

# Read the service file
fleetctl cat kube-apiserver.service

# Check the status/history of the service
fleetctl status kube-apiserver.service

# output the logs
# pass -f flag to streams the output of the service on terminal
fleetctl journal (-f) kube-apiserver.service

# etcdctl setter and getter
etcdctl set first-etcd-key "Hello World"
etcdctl get first-etcd-key   # Hello World

# verify etcd can set a value
etcdctl ls SETTER_NAME
```

- using `systemctl` and `journalctl`

```bash
# To start a new unit, we need to tell systemd to create the symlink and then start the file
systemctl enable /etc/systemd/system/hello.service
systemctl start hello.service

# To verify the unit started, list of containers running with `docker ps` and read the unit's output with `journalctl`
journalctl -f -u hello.service
```

## Kubectl installation and config

#### Installation

```bash
KUBERNETES_VERSION=1.0.2
PLATFORM="darwin"

# wget -q --no-check-certificate -L -O /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/${PLATFORM}/amd64/kubectl"
wget -q --no-check-certificate -L -O /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v1.0.1/bin/darwin/amd64/kubectl"
chmod +x /usr/local/bin/kubectl
```
