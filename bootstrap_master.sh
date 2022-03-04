#!/bin/bash

echo "[TASK 1] Pull required containers"
kubeadm config images pull
# >/dev/null 2>&1

echo "[TASK 2] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=192.168.57.2 --pod-network-cidr=10.244.0.0/16 --apiserver-cert-extra-sans=controlplane,192.168.57.2,kmaster1
# >> /root/kubeinit.log 2>/dev/null


echo "[TASK 3] Kubectl config"
echo "Current user:" $(id)
mkdir -vp ~/.kube
cp -i /etc/kubernetes/admin.conf ~/.kube/config
chown $(id -u):$(id -g) ~/.kube/config

echo "[TASK 3.1] K8S aliases"
cat <<EOF | tee ~/.bash_aliases
alias k='kubectl'
alias ksys='kubectl -n kube-system'
EOF

# echo "[TASK 3] CNI Flannel network"
# kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# echo "[TASK 3] Deploy Calico network"
#kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1

echo "[TASK 3] CNI Weave-Net network"
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=10.244.0.0/16"

echo "[TASK 4] Generate and save cluster join command to /vagrant/joincluster.sh"
kubeadm token create --print-join-command > /vagrant/joincluster.sh
# 2>/dev/null
