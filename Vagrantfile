# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'
Vagrant.require_version ">= 1.6.0"

$num_nodes=ENV['NUM_NODES'] || 1
$base_ip_addr=ENV['BASE_IP_ADDR'] || "172.17.8"

# Change the version of CoreOS to be installed. Default: "current"
# For example, to deploy version 709.0.0, set $image_version="709.0.0"
$image_version = "current"

# which updates should be downloaded. E.G: 'stable', 'beta', 'alpha'
$update_channel = "alpha"

# Enable NFS sharing of your home directory ($HOME) to CoreOS
# It will be mounted at the same path in the VM as on the host.
# Example: /Users/foobar -> /Users/foobar
$share_home = false

# Share additional folders to the CoreOS VMs
# $shared_folders = {'shared/' => '/home/core/shared/'}
$shared_folders = {}

# Customize VMs
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 1

# Enable port forwarding from guest(s) to host machine,
# syntax is: { 80 => 8080 }, auto correction is enabled by default.
$forwarded_ports = {}

# Log the serial consoles of CoreOS VMs to log/
# Enable by setting value to true, disable with false
# WARNING: Serial logging is known to result in extremely high CPU usage with
# VirtualBox, so should only be used in debugging situations
$enable_serial_logging = false

# Enable port forwarding of Docker TCP socket
# Set to the TCP port you want exposed on the *host* machine, default is 2375
# You can then use the docker tool locally by setting the following env var:
#   export DOCKER_HOST='tcp://127.0.0.1:2375'
#$expose_docker_tcp=2375

$Vagrantfile_api_version = "2"

# load up cloud-init files, and startup bash scripts
$master_data_path = File.join(File.dirname(__FILE__), "setup/cloud-init/master-data")
$node_data_path = File.join(File.dirname(__FILE__), "setup/cloud-init/node-data")
$etcd_start_script_path = File.join(File.dirname(__FILE__), "setup/etcd-start")

# Use old vb_xxx config variables when set
def vm_gui
  $vb_gui.nil? ? $vm_gui : $vb_gui
end

def vm_memory
  $vb_memory.nil? ? $vm_memory : $vb_memory
end

def vm_cpus
  $vb_cpus.nil? ? $vm_cpus : $vb_cpus
end

Vagrant.configure($Vagrantfile_api_version) do |config|
  # always use Vagrants insecure key
  config.ssh.insert_key = false

  config.vm.box = "coreos-%s" % $update_channel
  if $image_version != "current"
      config.vm.box_version = $image_version
  end
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [$update_channel, $image_version]

  ["vmware_fusion", "vmware_workstation"].each do |vmware|
    config.vm.provider vmware do |v, override|
      override.vm.box_url = "http://%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant_vmware_fusion.json" % [$update_channel, $image_version]
    end
  end

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  (0..$num_nodes).each do |i|
    if i == 0
      hostname = "kube-master"
      role = "master"
    else
      hostname = "kube-node-%02d" % i
      role = "node"
    end
	ip = "%s.%d" % [$base_ip_addr, i+100]

    config.vm.define vm_name = hostname do |config|
      config.vm.hostname = vm_name

      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "%s-serial.txt" % vm_name)
        FileUtils.touch(serialFile)

        ["vmware_fusion", "vmware_workstation"].each do |vmware|
          config.vm.provider vmware do |v, override|
            v.vmx["serial0.present"] = "TRUE"
            v.vmx["serial0.fileType"] = "file"
            v.vmx["serial0.fileName"] = serialFile
            v.vmx["serial0.tryNoRxLoss"] = "FALSE"
          end
        end

        config.vm.provider :virtualbox do |vb, override|
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end
      end

      if $expose_docker_tcp
        config.vm.network "forwarded_port", guest: 2375, host: $expose_docker_tcp, auto_correct: true
      end

      # Create a forwarded port mapping which allows access to a specific port
      # within the machine from a port on the host machine.
      # ex: config.vm.network "forwarded_port", guest: 49156, host: 9876
      $forwarded_ports.each do |guest, host|
        config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
      end

      ["vmware_fusion", "vmware_workstation"].each do |vmware|
        config.vm.provider vmware do |v|
          v.gui = vm_gui
          v.vmx['memsize'] = vm_memory
          v.vmx['numvcpus'] = vm_cpus
        end
      end

      config.vm.provider :virtualbox do |vb|
        vb.gui = vm_gui
        vb.memory = vm_memory
        vb.cpus = vm_cpus
      end

      config.vm.network :private_network, ip: ip

      # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
      #config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      $shared_folders.each_with_index do |(host_folder, guest_folder), index|
        config.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "core-share%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
      end

      if $share_home
        config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      end

      system "echo '\n********\nCurrent Role: #{role} \nMachine Name: #{hostname}\n********\n'"
      if role == "master"
        config.vm.provision :file, :source => $master_data_path, :destination => "/tmp/vagrantfile-user-data"
        config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true

        # kick start etcd2 service
        config.vm.provision :file, :source => $etcd_start_script_path, :destination => "/tmp/etcd-start"
        config.vm.provision :shell, :inline => "chmod +x /tmp/etcd-start && /tmp/etcd-start", :privileged => true
      else
        config.vm.provision :file, :source => $node_data_path, :destination => "/tmp/vagrantfile-user-data"
        config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
      end
    end
  end
end
