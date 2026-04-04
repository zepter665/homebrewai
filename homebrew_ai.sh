#######################################
# apt install docker.io -y

## Docker Runtime Install
wget https://download.docker.com/linux/static/stable/x86_64/docker-29.3.1.tgz
tar zxvf docker-29.3.1.tgz
sudo cp docker/* /usr/bin/
rm ./docker -R
rm docker-29.3.1.tgz
sudo groupadd docker 2>&1
sudo mkdir /etc/docker
# Daemon Install
install ./services/containerd.service /etc/systemd/system
install ./services/docker.service /etc/systemd/system
install ./services/docker.socket /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl start containerd
sudo systemctl enable docker.socket
sudo systemctl enable docker.service
sudo systemctl start docker

## Conntrack Install
sudo cp ./binaries/conntrack /usr/sbin/conntrack
sudo chmod 755 /usr/sbin/conntrack

## Container Runtime Interface Control (crictl) Install
VERSION="v1.31.0" # check latest version in /releases page
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
tar zxvf crictl-$VERSION-linux-amd64.tar.gz
sudo cp crictl /usr/local/bin/crictl
sudo chmod 755 /usr/local/bin/crictl
rm -f ./crictl
rm -f crictl-$VERSION-linux-amd64.tar.gz

## Container Network Interface (cni) Install
CNI_PLUGIN_VERSION="v1.9.1"
CNI_PLUGIN_TAR="cni-plugins-linux-amd64-$CNI_PLUGIN_VERSION.tgz" # change arch if not on amd64
CNI_PLUGIN_INSTALL_DIR="/opt/cni/bin"
wget "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/$CNI_PLUGIN_TAR"
sudo mkdir -p "$CNI_PLUGIN_INSTALL_DIR"
sudo tar -xf "$CNI_PLUGIN_TAR" -C "$CNI_PLUGIN_INSTALL_DIR"
rm "$CNI_PLUGIN_TAR"

## Container Runtime Interface dockerd (cri-dockerd) Install
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.4.2/cri-dockerd-0.4.2.amd64.tgz
sudo tar zxvf cri-dockerd-0.4.2.amd64.tgz
install -o root -g root -m 0755 ./cri-dockerd/cri-dockerd /usr/local/bin/cri-dockerd
install ./services/cri-docker.service /etc/systemd/system
install ./services/cri-docker.socket /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable --now cri-docker.socket
service cri-docker start
rm ./cri-dockerd -R
rm cri-dockerd-0.4.2.amd64.tgz

## MiniKube Install
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
minikube start --driver=none --cni calico
sudo minikube config set driver none

## kubectl Install
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm ./kubectl

## HELM  Install
wget https://get.helm.sh/helm-v4.1.3-linux-amd64.tar.gz
tar zxvf helm-v4.1.3-linux-amd64.tar.gz
sudo install -o root -g root -m 0755 ./linux-amd64/helm /usr/local/bin/helm
rm ./helm-v4.1.3-linux-amd64.tar.gz
rm ./linux-amd64 -R

## Kube-Config für externe Verwendung anpassen
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



