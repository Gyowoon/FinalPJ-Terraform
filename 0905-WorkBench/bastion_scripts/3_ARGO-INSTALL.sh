#!/bin/bash
#set -euo pipefail

# Required variables check
: "${REGION:?Required variable REGION is not set}"
: "${CLUSTER_NAME:?Required variable CLUSTER_NAME is not set}"

# Color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[START] Installing Argo CD CLI and Helm chart${NC}"

# Temporary directory for downloads
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

# Update kubeconfig with error handling
if ! aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" --alias "$CLUSTER_NAME"; then
    echo -e "${RED}Failed to update kubeconfig${NC}"
    exit 1
fi

# Install argocd CLI with version check
if ! command -v argocd >/dev/null 2>&1; then
    echo "Downloading latest Argo CD CLI..."
    ARGOCD_VERSION=$(curl -sL https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -sSL -o "${TEMP_DIR}/argocd" \
        "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
    if [ $? -eq 0 ]; then
        sudo mv "${TEMP_DIR}/argocd" /usr/local/bin/argocd
        sudo chmod +x /usr/local/bin/argocd
    else
        echo -e "${RED}Failed to download Argo CD CLI${NC}"
        exit 1
    fi
fi


# Ensure the argocd namespace exists
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd

# Add the Argo Helm repository and update the repo cache
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

# Enhanced Helm install with timeout and error handling
if ! helm upgrade --install argo-cd argo/argo-cd \
    --namespace argocd \
    --timeout 5m \
    --set server.service.type=LoadBalancer \
    --set configs.cm.create=true \
    --set configs.cm.name=argocd-cm \
    --set configs.rbac.create=true \
    --set configs.rbac.name=argocd-rbac-cm \
    --set configs.params.create=true \
    --set configs.params.name=argocd-cmd-params-cm \
    --set configs.tls.create=true \
    --set configs.tls.name=argocd-tls-certs-cm \
    --set configs.knownHosts.create=true \
    --set configs.knownHosts.name=argocd-ssh-known-hosts-cm \
    --set configs.gpgKeys.create=true \
    --set configs.gpgKeys.name=argocd-gpg-keys-cm; then
    echo -e "${RED}Failed to install Argo CD${NC}"
    exit 1
fi

# Wait for rollout with timeout
echo "Waiting for Argo CD server deployment..."
if ! timeout 300 kubectl -n argocd rollout status deployment/argo-cd-argocd-server; then
    echo -e "${RED}Timeout waiting for Argo CD server deployment${NC}"
    exit 1
fi

# Wait for LoadBalancer to be ready
echo "Waiting for LoadBalancer to be ready..."
for i in $(seq 1 30); do
    if EXTERNAL_IP=$(kubectl -n argocd get svc argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'); then
        echo "LoadBalancer endpoint: $EXTERNAL_IP"
        break
    fi
    echo "Waiting for LoadBalancer endpoint... ($i/30)"
    sleep 10
done

echo -e "${GREEN}[END] Argo CD installation completed successfully${NC}"
### END ###
