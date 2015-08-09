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
ROLE=master vagrant ssh -c 'cat /etc/systemd/system/etcd2.service.d/initial-cluster.conf'

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
