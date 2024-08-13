#!/bin/bash
###KUBEMASTER###

#System Settings
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

lsmod | grep br_netfilter
lsmod | grep overlay

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

#Installing CRI-O#

sudo apt-get update -y
sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" | tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o

sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service


#Installing Kubeadm, Kubelet & Kubectl#
KUBEVERSION=v1.30
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

sleep 12
echo "Waiting for 120 Seconds...."
echo "Lets initialize."

IPADDR=192.168.33.2
POD_CIDR=10.244.0.0/16
NODENAME=kubemaster
#kubeadm init --pod-network-cidr 10.244.0.0/16  --apiserver-advertise-address=192.168.33.2 > /tmp/kubeinitout.log
kubeadm init --control-plane-endpoint=$IPADDR    --pod-network-cidr=$POD_CIDR --node-name $NODENAME --ignore-preflight-errors Swap &>> /tmp/initout.log
sleep 10

cat /tmp/initout.log | grep -A2 mkdir | /bin/bash
sleep 10
tail -2 /tmp/initout.log > /vagrant/cltjoincommand.sh
