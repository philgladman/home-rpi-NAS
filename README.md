# home-rpi-NAS
Raspberry pi NAS for home environment

# Prereqs
- Raspberry Pi
- SD Card
- External Drive
- Raspberry Pi Imager installed (https://www.raspberrypi.com/software/)

# Raspberry Pi Setup
- Use Raspberry Pi Imager to write Ubuntu Server 20.04 LTS (64-BIT) to sd card
- After image has been succesfully written, Eject SD Card from computer, and then reinsert card into computer.
- click on SD Card, and open up the newly created `boot` or `system-boot` folder
- Open up the `network-config.txt` file in a txt editor, create this file if it does not exisit.
- Add the contents below to the end of the file, this will configure your static ip. Replace the ip address with your rpis ip, gateway ip, and dns ip.

```bash
version: 2
ethernets:
  eth0:
    addresses:
      - 192.168.1.152/24
    gateway4: 192.168.1.1
    nameservers:
      addresses: [192.168.1.110]
    optional: true
```

- In the `boot`  or `system-boot` folder, open up the `cmdline.txt` file in a txt editor
- Add the following `cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory` to the end of the top line, this will enable cgroups
- add a blank file named `ssh` into the `boot` or `system-boot` folder by running the following command. `touch ssh` to create the blank `ssh` file. Find newly created `ssh` file and move it into the sd cards `boot` or `system-boot` folder.
- Eject SD card and plug into rpi.
- Turn rpi on and let rpi boot up.
- ssh into the pi with `ssh ubuntu@<rpi-ip-address>`. The password will be `ubuntu`

# Setup hard drive
## Partition hardrive
- now that the Raspberry pi is up and running, lets prepare the hard drive
- Plug in hard drive to rpi.
- run `sudo fdisk -l` to find the drive, should be at the bottom, labeled something like`/dev/sda/`
- run `sudo fdisk /dev/sda` to partition the drive
- type in `d` and hit enter to delete, and then hit eneter to delete the default partition. Do this for each partiion on the drive.
- Now that all partions have been deleted, lets create a new partition.
- hit `n` and enter to create a new partition
- hit enter for default for `primary` partition
- hit enter for default for `1 partition number`.
- hit enter for default for `First sector` size.
- hit enter for default for `Last sector` size.
- Partition 1 has been created of type `linux`, now hit `w` to write, this will save/create the partion and exit out of fdisk.

## Make filesystem on hardrive
- Now make a filesystem on the newly created partition by running the following command `sudo mkfs -t ext4 /dev/sda1`

## Mount volume
- create directory to mount drive to `sudo mkdir /volume`
- mount hard drive to new directory `sudo mount /dev/sda1 /volume`
- change directory permissions `sudo chmod 777 -R /volume`
- create test file in new folder `touch /volume/test`
- list new file `ls /volume`
- Drive has now been mounted, however will not persist reboot.
- To make mount perisistent, edit /etc/fstab file with the following command `sudo vim /etc/fstab/` and add the following to the bottom of the existing mounts. `/dev/sda1 /volume ext4 defaults 0 2`
- reboot pi to confirm test file is still there `sudo reboot` and then once pi is back up, run `ls /volume`


# Deploy k3s single node cluster and configure samba
- create k3s cluster without install teaefik (we will use nginx ingress instead later) `curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh`
- copy newly created kubeconfig to home dir `mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown ubuntu:ubuntu ~/.kube/config`
- export kubeconfig `echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc && source ~/.bashrc`
- label master node so samba container will only run on master node since it has the external drive connected `kubectl label nodes <master-node-name> disk=disk1`
- install helm `curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash`
- clone git repo `git clone https://github.com/philgladman/home-rpi-NAS.git`
- cd into repo `cd home-rpi-NAS`
- deploy to cluster `kubectl apply -k .`
- FYI - release.yaml was created with the following command `helm template nginx-ingress nginx-ingress/ -f values.yaml --include-crds --debug > release.yaml`
- FYI - the only changes to the default values.yaml for the nginx-ingress were below
```bash
tcp: {}
#  8080: "default/example-tcp-svc:9000"
```
to this
```bash
tcp: 
  139: default/samba:139
  445: default/samba:445
```

## Configure samba
- `kubectl get pods` copy name of pod
- `export SAMBA_POD=<your-smaba-pod-name>` paste name of samba pod here
- `kubectl exec -it $SAMBA_POD -- vim /etc/samba/smb.conf` and paste in the contents below to the bottom of /etc/samba/smb.conf file

```bash
[Custom-name-of-NAS]
path=/path-to-mounted-drive-on-container
writeable=yes
public=no
```

- restart samba `kubectl exec -it $SAMBA_POD -- /etc/init.d/smbd restart`
- create new linux user in container for samba use `kubectl exec -it $SAMBA_POD -- adduser <username>` and type in new password
- create new smb user `kubectl exec -it $SAMBA_POD -- smbpasswd -a <username>` and type in new password
- connect to smb from computer,
- on mac, click on finder, then click `cmd+k`, type in `smb://<ip-of-pi>`, click connect, click connect again, and now type in your newly created username and password. Click on the name of the NAS that was created.
- in terminal downland smbclient `sudo apt install smbclient` and run `smbclient -L <rpi-ip-address> -U <smb-username>` and type in password. you will see the name of the new NAS under `Sharename`.
