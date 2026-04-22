#!/bin/bash
set -e

echo "=== HomebrewAI Deinstallation ==="
echo "WARNUNG: Alle Kubernetes-Workloads, Daten und installierten Komponenten werden entfernt!"
read -rp "Fortfahren? (yes/no): " CONFIRM
[[ "$CONFIRM" != "yes" ]] && echo "Abgebrochen." && exit 1

##################################################################
## KI deinstallieren (Helm)

echo "[1/8] Helm Releases entfernen..."
helm uninstall open-webui 2>/dev/null && echo "  open-webui entfernt" || echo "  open-webui nicht gefunden"
helm uninstall ollama 2>/dev/null && echo "  ollama entfernt" || echo "  ollama nicht gefunden"
helm repo remove open-webui 2>/dev/null || true
helm repo remove otwld 2>/dev/null || true

## MiniKube entfernen
echo "[2/8] MiniKube stoppen und löschen..."
minikube stop 2>/dev/null || true
minikube delete --all --purge 2>/dev/null || true
sudo rm -f /usr/local/bin/minikube
rm -rf ~/.minikube

## kubectl entfernen
echo "[3/8] kubectl entfernen..."
sudo rm -f /usr/local/bin/kubectl

## HELM entfernen
echo "[4/8] Helm entfernen..."
sudo rm -f /usr/local/bin/helm

## cri-dockerd entfernen
echo "[5/8] cri-dockerd entfernen..."
systemctl stop cri-docker 2>/dev/null || true
systemctl stop cri-docker.socket 2>/dev/null || true
systemctl disable cri-docker 2>/dev/null || true
systemctl disable cri-docker.socket 2>/dev/null || true
sudo rm -f /etc/systemd/system/cri-docker.service
sudo rm -f /etc/systemd/system/cri-docker.socket
sudo rm -f /usr/local/bin/cri-dockerd

## CNI Plugins entfernen
echo "[6/8] CNI Plugins entfernen..."
sudo rm -rf /opt/cni/bin

## crictl entfernen
echo "[7/8] crictl entfernen..."
sudo rm -f /usr/local/bin/crictl

## Docker entfernen
echo "[8/8] Docker entfernen..."
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl stop docker.socket 2>/dev/null || true
sudo systemctl stop containerd 2>/dev/null || true
sudo systemctl disable docker 2>/dev/null || true
sudo systemctl disable docker.socket 2>/dev/null || true
sudo systemctl disable containerd 2>/dev/null || true
sudo rm -f /etc/systemd/system/docker.service
sudo rm -f /etc/systemd/system/docker.socket
sudo rm -f /etc/systemd/system/containerd.service
sudo rm -f /usr/bin/docker
sudo rm -f /usr/bin/dockerd
sudo rm -f /usr/bin/containerd
sudo rm -f /usr/bin/containerd-shim
sudo rm -f /usr/bin/containerd-shim-runc-v2
sudo rm -f /usr/bin/ctr
sudo rm -f /usr/bin/runc
sudo rm -rf /etc/docker
sudo rm -f /usr/sbin/conntrack

## Systemd neu laden
sudo systemctl daemon-reload
sudo systemctl reset-failed 2>/dev/null || true

echo ""
echo "=== Deinstallation abgeschlossen ==="
echo "Hinweis: Docker-Gruppe wurde nicht entfernt. Bei Bedarf: sudo groupdel docker"
