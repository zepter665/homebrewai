# HomebrewAI

Bash-Skripte zum automatisierten Aufsetzen eines lokalen, "selbstgebauten" Kubernetes-Clusters (ohne Minikube-eigene Container-Runtime-Installation) auf einer einzelnen Linux-Maschine — inklusive einer lokal laufenden KI-Stack-Installation mit [Ollama](https://ollama.com/) und [Open WebUI](https://openwebui.com/).

Der Cluster nutzt Docker als Container-Runtime (über `cri-dockerd`) und Minikube mit dem `none`-Treiber, läuft also direkt auf dem Host statt in einer VM.

## Was wird installiert?

`homebrew_ai.sh` installiert und konfiguriert der Reihe nach:

| Komponente | Zweck |
|---|---|
| **Docker** (statisches Binary) + `containerd` | Container-Runtime |
| `conntrack` | Connection-Tracking (Kernel-Netzwerkkomponente, wird von Kubernetes benötigt) |
| `crictl` | CLI zur Fehleranalyse von Container-Workloads über die CRI |
| CNI-Plugins | Netzwerk-Plugins für Pod-Networking |
| `cri-dockerd` | Adapter, der Docker als Kubernetes-Container-Runtime (CRI) nutzbar macht |
| `minikube` (Treiber `none`, CNI `calico`) | lokaler Kubernetes-Cluster auf dem Host |
| `kubectl` | Kubernetes-CLI |
| `helm` | Kubernetes-Paketmanager |
| `ollama` (via Helm-Chart) | LLM-Server im Cluster |
| `open-webui` (via Helm-Chart) | Web-Oberfläche für den Chat mit dem LLM |

Anschließend wird `embed_kubeconfig_certs.sh` ausgeführt, um die `~/.kube/config` für den externen Zugriff (z. B. mit [FreeLens](https://freelens.app/)) nutzbar zu machen.

## Voraussetzungen

- Linux, `x86_64` (Skripte enthalten fest verdrahtete `amd64`-Downloads)
- `sudo`-Rechte
- Internetzugang (Downloads von Docker, GitHub Releases, Helm-Repos)
- Für den KI-Teil: ein bereits lokal vorhandenes Modell unter `/ollama-tmp/ollama`, das nach `/tmp/hostpath-provisioner/default/` kopiert wird (siehe Hinweis unten)

## Verwendung

### Installation

```bash
chmod +x homebrew_ai.sh
./homebrew_ai.sh
```

> **Hinweis:** `homebrew_ai.sh` ist aktuell eher als Schritt-für-Schritt-Ablaufprotokoll aufgebaut (kein vollständig durchgetestetes, idempotentes Setup-Skript). Es empfiehlt sich, die Abschnitte einzeln oder zumindest mit Blick auf die Kommentare auszuführen, insbesondere:
> - Versionsnummern (Docker, `crictl`, CNI-Plugins, `cri-dockerd`, Helm) ggf. vor dem Ausführen auf aktuelle Releases prüfen.
> - Der Ollama-Modell-Kopiervorgang (`/ollama-tmp/ollama`) setzt voraus, dass dort bereits ein Modell abgelegt wurde, um den erneuten Download zu vermeiden.
> - Nach der Installation kann der Cluster-Zugriff über FreeLens oder `kubectl` mit der angepassten `~/.kube/config` erfolgen.

Nach der Installation sind u. a. erreichbar:
- **Ollama API**: `http://<host-ip>:30667`
- **Open WebUI**: NodePort `30666`

### Deinstallation

```bash
chmod +x uninstall.sh
./uninstall.sh
```

Entfernt alle Helm-Releases, Minikube, `kubectl`, `helm`, `cri-dockerd`, CNI-Plugins, `crictl`, Docker/`containerd` sowie die zugehörigen systemd-Units. Fragt vor dem Ausführen eine Bestätigung ab. Die `docker`-Gruppe wird bewusst nicht entfernt (`sudo groupdel docker`, falls gewünscht).

### Kubeconfig für externen Zugriff anpassen

```bash
./embed_kubeconfig_certs.sh
```

Liest die in `~/.kube/config` referenzierten Zertifikats-/Schlüsseldateien (`certificate-authority`, `client-certificate`, `client-key`), bettet sie Base64-kodiert direkt in die Datei ein (`*-data`-Felder) und testet die Verbindung mit `kubectl get nodes`. Dadurch lässt sich die Kubeconfig auch außerhalb der Maschine verwenden, ohne dass die referenzierten Zertifikatsdateien mitkopiert werden müssen.

## Repository-Struktur

```
homebrew_ai.sh              Hauptinstallationsskript (Runtime, Kubernetes, KI-Stack)
uninstall.sh                Entfernt alle installierten Komponenten wieder
embed_kubeconfig_certs.sh   Bettet Zertifikate in ~/.kube/config ein
binaries/
  conntrack                 Statisches conntrack-Binary
services/
  containerd.service        systemd-Unit für containerd
  docker.service             systemd-Unit für Docker
  docker.socket              systemd-Socket für Docker
  cri-docker.service          systemd-Unit für cri-dockerd
  cri-docker.socket           systemd-Socket für cri-dockerd
```

## Sicherheitshinweise

- Die Skripte führen zahlreiche Befehle mit `sudo` aus und laden Binaries von externen Quellen (Docker, GitHub Releases, Helm-Repos) herunter — vor produktivem Einsatz Quellen und Checksums prüfen.
- `open-webui` und `ollama` werden per NodePort ohne TLS/Auth-Konfiguration exponiert; für den Einsatz über das lokale Testsystem hinaus sollte zusätzlich Absicherung (Ingress mit TLS, Authentifizierung, Netzwerk-Policies) ergänzt werden.
