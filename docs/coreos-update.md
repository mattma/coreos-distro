Based on the [docs](https://coreos.com/os/docs/latest/update-strategies.html)

Find current version of CoreOS

```bash
cat /etc/os-release

# show machine id of this host
cat /etc/machine-id

# show the strategy in the current setup
cat /etc/coreos/update.conf
```

Lock the machine for any active activity

```bash
# check the status of the current machine
sudo locksmithctl status

# lock the current machine
sudo locksmithctl lock
```

Manually Triggering an Update

```bash

# nitiating update check and install.
update_engine_client -check_for_update

# check the current statue of the update
update_engine_client -status
# CURRENT_OP=UPDATE_STATUS_UPDATED_NEED_REBOOT

# login on the coreos machines, manually update
# /usr/bin/update_engine_client -update

# if you run `locksmithctl lock`, you need to unlock
sudo locksmithctl unlock
sudo locksmithctl reboot

# reboot the system
sudo reboot
```

```bash
sudo iptables-save
```
