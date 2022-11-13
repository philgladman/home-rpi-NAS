sudo mkdir /NAS-volume

sudo groupadd smbusers -g 1010

sudo chown root:smbusers -R /NAS-volume

sudo chmod 770 -R /NAS-volume

sudo echo "/dev/sda1 /NAS-volume ext4 defaults 0 2" | sudo tee -a /etc/fstab

sudo mount -a

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh

mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown ubuntu:ubuntu ~/.kube/config

echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc && source ~/.bashrc

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo "username" > samba/smbuser

echo "password" > samba/smbpass

kubectl label nodes $(hostname) disk=disk1

kubectl apply -k .