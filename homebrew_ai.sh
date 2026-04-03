### PREREQUIREMENTS ###

# wget https://download.docker.com/linux/static/stable/x86_64/docker-29.3.1.tgz
# sudo tar zxvf docker-29.3.1.tgz
# sudo rm -f docker-29.3.1.tgz

# apt install conntrack -y

# VERSION="v1.31.0" # check latest version in /releases page
# wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
# sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
# rm -f crictl-$VERSION-linux-amd64.tar.gz

# wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.4.2/cri-dockerd-0.4.2.amd64.tgz
# sudo tar zxvf cri-dockerd-0.4.2.amd64.tgz

# CNI_PLUGIN_VERSION="v1.9.1"
# CNI_PLUGIN_TAR="cni-plugins-linux-amd64-$CNI_PLUGIN_VERSION.tgz" # change arch if not on amd64
# CNI_PLUGIN_INSTALL_DIR="/opt/cni/bin"

# curl -LO "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/$CNI_PLUGIN_TAR"
# sudo mkdir -p "$CNI_PLUGIN_INSTALL_DIR"
# sudo tar -xf "$CNI_PLUGIN_TAR" -C "$CNI_PLUGIN_INSTALL_DIR"
# rm "$CNI_PLUGIN_TAR"

# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# wget https://get.helm.sh/helm-v4.1.3-linux-amd64.tar.gz
# sudo tar zxvf helm-v4.1.3-linux-amd64.tar.gz

#######################################

# apt install docker.io -y
sudo cp docker/* /usr/bin/
sudo groupadd docker 2>&1
sudo mkdir /etc/docker

install containerd.service /etc/systemd/system
install docker.service /etc/systemd/system
install docker.socket /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl start containerd
sudo systemctl enable docker.socket
sudo systemctl enable docker.service
sudo systemctl start docker

sudo cp conntrack /usr/sbin/conntrack
sudo chmod 755 /usr/sbin/conntrack

sudo cp crictl /usr/local/bin/crictl
sudo chmod 755 /usr/local/bin/crictl

sudo cp cni /opt/ -R
sudo chmod 755 /opt/cni/bin/* -R

install -o root -g root -m 0755 cri-dockerd /usr/local/bin/cri-dockerd
install cri-docker.service /etc/systemd/system
install cri-docker.socket /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable --now cri-docker.socket

service cri-docker start

curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

minikube start --driver=none --cni calico
sudo minikube config set driver none

# kubectl
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# HELM
install -o root -g root -m 0755 helm /usr/local/bin/helm

# Kube-Config für externe Verwendung anpassen
chmod +x ./embed_kubeconfig_certs.sh 
./embed_kubeconfig_certs.sh 
##################################################################
## KI installieren

# Ollama installieren (HELM)
helm repo add otwld "https://helm.otwld.com/"

helm install ollama otwld/ollama \
--set ollama.port="11434" \
--set ollama.gpu.enabled=false \
--set ollama.models.pull={mistral} \
--set ollama.models.run={mistral} \
--set persistentVolume.enabled=false

# OpenWebUI installieren (HELM)
helm repo add open-webui "https://helm.openwebui.com/"

helm install open-webui open-webui/open-webui \
--set ollama.enabled=false \
--set ollamaUrls={http://ollama.default.svc.cluster.local:11434} \
--set websocket.enabled=true \
--set websocket.manager=redis \
--set websocket.url="redis://open-webui-redis:6379/0" \
--set websocket.redis.enabled=true \
--set tika.enabled=true \
--set persistence.enabled=false \
--set pipelines.enabled=true \
--set service.type=NodePort \
--set service.nodePort=30666



