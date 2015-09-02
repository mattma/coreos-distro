Based on the [docs](https://coreos.com/os/docs/latest/update-strategies.html)

Find current version of CoreOS

```bash
cat /etc/os-release

# show machine id of this host
cat /etc/machine-id

# show the strategy in the current setup
cat /etc/coreos/update.conf
```

Lock the machine for any active activity. [Locksmith](https://github.com/coreos/locksmith)

```bash
update_engine_client -status

# check the status of the current machine
locksmithctl status

# lock the current machine
locksmithctl lock
```

Manually Triggering an Update

```bash

# Initiating update check and install.
update_engine_client -check_for_update

# check the current statue of the update
update_engine_client -status
# CURRENT_OP=UPDATE_STATUS_UPDATED_NEED_REBOOT

# login on the coreos machines, manually update
# /usr/bin/update_engine_client -update

# if you run `locksmithctl lock`, you need to unlock
locksmithctl unlock

# reboot locksmith if it is needed, but it needs to be root
# locksmithctl reboot

# reboot the system
sudo reboot
```

**Unlock Holders** do it if anything bad happens

If a machine may go away permanently or semi-permanently while holding a reboot lock. A system administrator can clear the lock of a specific machine using the unlock command:

```bash
# check the current status of locksmith status
etcdctl get coreos.com/updateengine/rebootlock/semaphore

locksmithctl unlock MACHINE_ID
```

```bash
sudo iptables-save
```
