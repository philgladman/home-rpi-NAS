# home-rpi-NAS
Raspberry pi NAS for home environment

# Prereqs
- raspberry pi
- SD Card
- external drive
- Raspberry Pi Imager installed (https://www.raspberrypi.com/software/)

# Rpi pre boot setup
- Use Raspberry Pi Imager to write Ubuntu Server 20.04 LTS (64-BIT) to sd card
- After image has been succesfully written, click on SD Card, and open up the newly created `boot` or `system-boot` folder
- In the `boot`  or `system-boot` folder, open up the `network-config.txt` file in a txt editor
- Add the contents below  to the end of the top line;

```bash
version: 2
ethernets:
  eth0:
    addresses:
      - 192.168.1.152/24         # <-- replace with ipaddress for your pi
    gateway4: 192.168.1.1        # <-- replace with your networks gateway
    nameservers:
      addresses: [192.168.1.110] # <-- replace with your dns server of choice
    optional: true
```

- add a blank file named `ssh` into the `boot` or `system-boot` folder by running the following command. `touch ~/ssh` to create the blank `ssh` file. Find newly created `ssh` file and move it into the sd cards `boot` or `system-boot` folder.
- Eject SD card and plug into rpi.
- Turn rpi on and let rpi boot up.
- ssh into the pi with ssh ubuntu@<ip-address>. The password will be ubuntu

# Setup hard drive
## Partition hardrive
- now that the Raspberry pi is up and running, lets prepare the hard drive
- Plug in hard drive to rpi.
- run `sudo fdisk -l` to find the drive, should be at the bottom, labeled `/dev/sda/`
- run `sudo fdisk /dev/sda`
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

# Install docker
- sudo apt install docker.io
- curl -fsSL https://get.docker.com/rootless | sh
- export PATH=/home/ubuntu/bin:$PATH
- export DOCKER_HOST=unix:///run/user/1000/docker.sock

# Install and configure Samba
- Create custom samba container with Dockerfile, or use prebuilt docker image at `philgman1121/samba`
- spin up samba container `sudo docker run -d -p 139:139 -p 445:445 -v /test:/test --name test philgman1121/samba`
- `sudo docker exec -it test vim /etc/samba/smb.conf` and paste in the contents below to the bottom of /etc/samba/smb.conf file

```bash
[testNAS]     # <-- custom name to call your NAS
path=/test    # <-- path on the samba contaier to where the drive is mounted on
writeable=yes # 
public=no     # <-- requires a samba user and pass to access
```

- restart samba `sudo docker exec -it test /etc/init.d/smbd restart`
- create new linux user in container for samba use `sudo docker exec -it test adduser <username>` and type in new password
- create new smb user `sudo docker exec -it test smbpasswd -a <username>` and type in new password
- connect to smb from computer, on mac, click on finder, then click `cmd+k`, type in `smb://<ip-of-pi>`, click connect, click connect again, and now type in your newly created username and password. Click on the name of the NAS that was created.


# TODO - How to deploy on a kubernetes cluster
