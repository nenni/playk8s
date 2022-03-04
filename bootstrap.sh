#!/bin/bash

echo "[TASK 1] Disable SWAP"
swapoff -a

echo "[TASK 2] Timezone"
timedatectl set-timezone "Europe/London" >/dev/null 2>&1

echo "[TASK 3] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 4] Enable bridge filter kernel"
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

modprobe br_netfilter
modprobe overlay

echo "[TASK 5] Letting iptables see bridged traffic"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >/dev/null 2>&1



echo "[TASK 6] Update /etc/hosts file"
sed -i "/$(hostname)/s/^/#/g" /etc/hosts

cat <<EOF | tee -a /etc/hosts
192.168.57.2    kmaster1.k8s.local    kmaster1
192.168.57.11   knode1.k8s.local      knode1
192.168.57.12   knode2.k8s.local      knode2
EOF

echo "[TASK 7] SSH keys"
# SSH key generation
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -q -N ""
mkdir -p /vagrant/sshkeys/$(hostname)
cp -p ~/.ssh/id_ed25519* /vagrant/sshkeys/$(hostname)

echo "[TASK 8] Update APT"
apt-get update

echo "##################################"

echo "[TASK 21] Install Docker"
apt-get install -y docker.io containerd

echo "[TASK 22] Docker change cgroup to systemd same as kubelet"
cat <<EOF | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl restart docker


echo "[TASK 23] Update vagrant user, adding to docker group"
usermod -aG docker vagrant

echo "##################################"
echo "[TASK 30] Install curl"
apt-get install -y apt-transport-https ca-certificates curl

echo "##################################"
echo "[TASK 40] Get K8S apt source list"
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

echo "[TASK 41] Install kubeadm, kubelet, kubectl"
apt-get update

# apt-cache madison kubeadm ## check available version of kubeadm
# kube_version='1.22.7-00'
kube_version='1.23.4-00'

if [ -z "$kube_version" ]
then
      echo "Install latest version"
      apt-get install -y kubelet kubeadm kubectl
else
      echo "Install kubeadmin, kubelet, kubectl version:" $kube_version
      apt-get install -y kubelet=$kube_version kubeadm=$kube_version kubectl=$kube_version
fi

apt-mark hold kubelet kubeadm kubectl
