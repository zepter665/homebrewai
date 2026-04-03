#!/usr/bin/env bash
set -euo pipefail

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Liest den Wert eines Feldes aus der kubeconfig (z.B. certificate-authority)
get_field() {
    local field="$1"
    grep "$field:" "$KUBECONFIG" | awk '{print $2}'
}

# Ersetzt ein Dateipfad-Feld durch ein eingebettetes Base64-Daten-Feld
embed_field() {
    local old_field="$1"
    local new_field="$2"
    local file_path
    file_path=$(get_field "$old_field")

    if [[ -z "$file_path" ]]; then
        echo "Feld '$old_field' nicht gefunden, wird übersprungen."
        return
    fi

    if [[ ! -f "$file_path" ]]; then
        echo "Datei '$file_path' nicht gefunden, wird übersprungen."
        return
    fi

    local b64_data
    b64_data=$(base64 -w 0 "$file_path")

    sed -i "s|    ${old_field}: .*|    ${new_field}: ${b64_data}|" "$KUBECONFIG"
    echo "Eingebettet: $old_field -> $new_field (Quelle: $file_path)"
}

echo "Verarbeite kubeconfig: $KUBECONFIG"

embed_field "certificate-authority"  "certificate-authority-data"
embed_field "client-certificate"     "client-certificate-data"
embed_field "client-key"             "client-key-data"

echo "Fertig. Teste Verbindung..."
kubectl get nodes
