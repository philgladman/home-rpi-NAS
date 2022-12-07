# Home NAS on k3s cluster on Raspberry Pi
#### Description
- This repository has the configuration to create a Home NAS (Network Attached Storage) on a k3s cluster that is running on a Raspberry Pi. This configuration is utilizing Kustomization & Helm Charts, and is being deployed with GitOps via ArgoCD.

# Prereqs
- Raspberry Pi
- SD Card
- External Drive

## Step 1.) - Raspberry Pi Setup
- Please follow this link for instructions on [How to install and setup K3s Cluster on raspberry pi](https://github.com/philgladman/home-rpi-k3s-cluster.git)


## Step 2.) - Setup external drive
- now that the Raspberry pi is up and running with K3s, lets prepare the external drive
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

## Step 2.) - Mount volume
- create directory to mount drive to `sudo mkdir /NAS-volume`
- create smbusers group `sudo groupadd smbusers -g 1010`
- change group ownership `sudo chown root:smbusers -R /NAS-volume`
- change directory permissions `sudo chmod 770 -R /NAS-volume`
- To make mount perisistent, edit /etc/fstab file with the following command `sudo vim /etc/fstab/` and add the following to the bottom of the existing mounts. `/dev/sda1 /NAS-volume ext4 defaults 0 2`
- mount the drive `sudo mount -a`

## Step 3.) - Label Master node
- label master node so samba container will only run on master node since it has the external drive connected `kubectl label nodes $(hostname) disk=disk1`

## Step 4.) - Deploy apps with ArgoCD
- clone git repo `git clone https://github.com/philgladman/home-rpi-NAS.git`
- cd into repo `cd home-rpi-NAS`
- add a username for smbuser, this will be the user/pass you will use to access the NAS `echo -n "username" > kustomize/samba/smbcredentials/smbuser`
- add password for smbuser `echo -n "testpassword" > kustomize/samba/smbcredentials/smbpass`
- deploy all with `kubectl apply -k kustomize/.`
- If you receive an error such as `ensure CRDs are installed first`, re run the kubectl apply command.
- when all pods are up, get ArgoCD admin password `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo`
- port forward ArgoCD service `kubectl port-forward svc/argocd-server 8080:8080 -n argocd`
- login to argocd `localhost:8080`, sign in with user=admin and password that you just retrieved
- Watch ArgoCD console until the ingress and samba app are both healthy and synced
- Home NAS on k3s cluster on Raspberry Pi has now been deployed
- test out access to NAS. [Step 6.) - Test and confirm access to NAS](/README.md#step-6---test-and-confirm-access-to-nas)
- FYI - `kustomize/nginx-ingress/release.yaml` was created with the following command `helm template nginx-ingress charts/nginx-ingress -f kustomize/nginx-ingress/values.yaml --include-crds --debug > kustomize/nginx-ingress/release.yaml`
- FYI - the only changes to the default values.yaml for the nginx-ingress were below
```bash
tcp: {}
#  8080: "default/example-tcp-svc:9000"
```
to this
```bash
tcp: 
  139: samba/samba:139
  445: samba/samba:445
```

## Step 5.) - Customize the samba configuration
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

## Step 6.) - Test and confirm access to NAS
- connect to smb from computer,
- on mac, click on finder, then click `cmd+k`, type in `smb://<ip-of-pi>`, click connect, click connect again, and now type in your newly created username and password. Click on the name of the NAS that was created.
- in terminal, downland smbclient `sudo apt install smbclient` and run `smbclient -L <rpi-ip-address> -U <smb-username>` and type in password. you will see the name of the new NAS under `Sharename`.
