# Home NAS on k3s cluster on Raspberry Pi

# Prereqs
- Raspberry Pi
- SD Card
- External Drive
- Raspberry Pi Imager installed (https://www.raspberrypi.com/software/)

## Step 1.) - Raspberry Pi Setup
- Use Raspberry Pi Imager to write Ubuntu Server 20.04 LTS (64-BIT) to sd card
- After image has been succesfully written, Eject SD Card from computer, and then reinsert card into computer.
- click on SD Card, and open up the newly created `boot` or `system-boot` folder
- Open up the `network-config.txt` file in a txt editor, create this file if it does not exisit.
- Add the contents below to the end of the file, this will configure your static ip. Replace the ip address with the ip address you want your rpi to have. Also replace the gateway ip, and dns ip with your home networks values.

```bash
version: 2
ethernets:
  eth0:
    addresses:
      - 192.168.1.x/24
    gateway4: 192.168.1.x
    nameservers:
      addresses: [192.168.1.x]
    optional: true
```

- In the `boot`  or `system-boot` folder, open up the `cmdline.txt` file in a txt editor
- Add the following `cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory` to the end of the top line, this will enable cgroups
- add a blank file named `ssh` into the `boot` or `system-boot` folder by running the following command. `touch ssh` to create the blank `ssh` file. Find newly created `ssh` file and move it into the sd cards `boot` or `system-boot` folder.
- Eject SD card and plug into rpi.
- Turn rpi on and let rpi boot up.
- ssh into the pi with `ssh ubuntu@<rpi-ip-address>`. The password will be `ubuntu`

## Step 2.) - Setup external drive
- now that the Raspberry pi is up and running, lets prepare the external drive
- Plug in external drive to rpi.
- run `sudo fdisk -l` to find the drive, should be at the bottom, labeled something like`/dev/sda/`
- run `sudo fdisk /dev/sda` to partition the drive
- type in `d` and hit enter to delete, and then hit eneter to delete the default partition. Do this for each partition on the drive.
- Now that all partions have been deleted, lets create a new partition.
- hit `n` and enter to create a new partition
- hit enter for default for `primary` partition
- hit enter for default for `1 partition number`.
- hit enter for default for `First sector` size.
- hit enter for default for `Last sector` size.
- Partition 1 has been created of type `linux`, now hit `w` to write, this will save/create the partion and exit out of fdisk.
- Now make a filesystem on the newly created partition by running the following command `sudo mkfs -t ext4 /dev/sda1`

## Step 3.) - Deployment (Quick Method)
- for more in-depth deployment, skip this step and move on to [Step 4.)](/README.md#step-4---mount-volume)
- clone git repo `git clone https://github.com/philgladman/home-rpi-NAS.git`
- cd into repo `cd home-rpi-NAS`
- create file `samba/smbuser` and file `samba/smbpass`
- add `yourusername` to the `samba/smbuser` file
- add `yourpassword` to the `samba/smbuser` file
- run deploy.sh script `/bin/bash deploy.sh`
- Home NAS on k3s cluster on Raspberry Pi has now been deployed
- To change the name of the NAS or the volume that the NAS is mounted on, skip ahead to [Step 7.) - Customize the samba configuration](/README.md#step-7---customize-the-samba-configuration)
- to test access to NAS, skip ahead to [Step 8.) - Test and confirm access to NAS](/README.md#step-8---test-and-confirm-access-to-nas)

## Step 4.) - Mount volume
- create directory to mount drive to `sudo mkdir /NAS-volume`
- create smbusers group `sudo groupadd smbusers -g 1010`
- change group ownership `sudo chown root:smbusers -R /NAS-volume`
- change directory permissions `sudo chmod 770 -R /NAS-volume`
- To make mount perisistent, edit /etc/fstab file with the following command `sudo vim /etc/fstab/` and add the following to the bottom of the existing mounts. `/dev/sda1 /NAS-volume ext4 defaults 0 2`
- mount the drive `sudo mount -a`

## Step 5.) - Deploy and configure k3s single node cluster
- create k3s cluster without install teaefik (we will use nginx ingress instead later) `curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh`
- copy newly created kubeconfig to home dir `mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown ubuntu:ubuntu ~/.kube/config`
- export kubeconfig `echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc && source ~/.bashrc`
- label master node so samba container will only run on master node since it has the external drive connected `kubectl label nodes $(hostname) disk=disk1`
- install helm `curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash`

## Step 6.) - Deploy apps with ArgoCD
- clone git repo `git clone https://github.com/philgladman/home-rpi-NAS.git`
- cd into repo `cd home-rpi-NAS`
- create file `kustomize/samba/smbuser` and file `kustomize/samba/smbpass`
- add `yourusername` to the `kustomize/samba/smbuser` file
- add `yourpassword` to the `kustomize/samba/smbpass` file
- deploy argocd and argo ns `kubectl apply -k kustomize/argocd/.`
- when pods are up, get admin password `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo`
- port forward service `kubectl port-forward svc/argocd-server 8080:8080 -n argocd`
- login to argocd `localhost:8080`, sign in with user=admin and password that you just retrieved
- deploy master app `kubectl apply -f kustomize/apps/master-app.yaml`
- Watch ArgoCD console until the ingress and samba app are both healthy and synced
- Home NAS on k3s cluster on Raspberry Pi has now been deployed
- test out access to NAS. [Step 8.)](/README.md#step-8---test-and-confirm-access-to-NAS)
- FYI - `kustomize/nginx-ingress/release.yaml` was created with the following command `helm template nginx-ingress nginx-ingress/ -f values.yaml --include-crds --debug > release.yaml`
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

## Step 7.) - Customize the samba configuration
- To change the name of the NAS or the volume that the NAS is mounted on, run the commands below
- `kubectl get pods` copy name of samba pod
- `export SAMBA_POD=<your-smaba-pod-name>` paste name of samba pod here
- `kubectl exec -it $SAMBA_POD -- vim /etc/samba/smb.conf`, scroll to the bottom of the file, and edit the contents below,

```bash
[k3s-pi-NAS]
path=/NAS-volume
writeable=yes
public=no
```

- restart samba `kubectl exec -it $SAMBA_POD -- /etc/init.d/smbd restart`

## Step 8.) - Test and confirm access to NAS
- connect to smb from computer,
- on mac, click on finder, then click `cmd+k`, type in `smb://<ip-of-pi>`, click connect, click connect again, and now type in your newly created username and password. Click on the name of the NAS that was created.
- in terminal, downland smbclient `sudo apt install smbclient` and run `smbclient -L <rpi-ip-address> -U <smb-username>` and type in password. you will see the name of the new NAS under `Sharename`.
