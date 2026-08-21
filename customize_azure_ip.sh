#!/bin/bash

KUBECONFIG="${HOME}/.kube/config"
OLD_IP="10.0.0.4"
NEW_IP="20.218.132.124"

update_kubeconfig_ip() {
    if [[ ! -f "$KUBECONFIG" ]]; then
        echo "Error: $KUBECONFIG not found."
        return 1
    fi

    if ! grep -q "$OLD_IP" "$KUBECONFIG"; then
        echo "IP $OLD_IP not found in $KUBECONFIG – nothing to do."
        return 0
    fi

    sed -i "s|https://${OLD_IP}:|https://${NEW_IP}:|g" "$KUBECONFIG"
    echo "Updated server IP from $OLD_IP to $NEW_IP in $KUBECONFIG"
}

update_kubeconfig_ip
