sudo mkdir -p /NAS-volume

sudo groupadd smbusers -g 1010

sudo chown root:smbusers -R /NAS-volume

sudo chmod 770 -R /NAS-volume

sudo echo "/dev/sda1 /NAS-volume ext4 defaults 0 2" | sudo tee -a /etc/fstab

sudo mount -a

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh

mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown ubuntu:ubuntu ~/.kube/config

echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc && source ~/.bashrc

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

cat >"kustomize/samba/smbcredentials/smbuser" <<EOF
username
EOF

cat >"kustomize/samba/smbcredentials/smbpass" <<EOF
password
EOF

NUM_NODES_SUCCESS=1
NUM_NODES_READY=0
while [[ $NUM_NODES_READY -ne $NUM_NODES_SUCCESS ]]
do 
    NUM_NODES_READY=`kubectl get nodes | grep Ready | wc -l | awk '{$1=$1;print}'`
    echo "$NUM_NODES_READY/1 Nodes are ready"
    sleep 2
done

kubectl label nodes $(hostname) disk=disk1

kubectl apply -k kustomize/.

NUM_ARGOCD_PODS_SUCCESS=7
NUM_ARGOCD_PODS_READY=0
while [[ $NUM_ARGOCD_PODS_READY -ne $NUM_ARGOCD_PODS_SUCCESS ]]
do
    NUM_ARGOCD_PODS_READY=`kubectl -n argocd get pods | grep Running | wc -l |  awk '{$1=$1;print}'`
    echo "$NUM_ARGOCD_PODS_READY/7 ArgoCD pods are ready"
    sleep 2
done

# run this again to make sure everything is created
kubectl apply -k kustomize/.

echo argocd-password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)

echo "kubectl port-forward svc/argocd-server 8080:8080 -n argocd"