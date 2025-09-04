# 5. Install Argo CD CLI and deploy Argo CD via Helm.  
# The bastion already has Helm installed (see user_data in the Terraform for aws_instance.bastion).
# We first install the argocd CLI for convenience, then use Helm to deploy the Argo CD chart into the cluster.
# The upgrade --install command makes this idempotent so re‑running the script does not cause failures.
echo "[START] Installing Argo CD CLI and Helm chart"

# Install argocd CLI if not already present
if ! command -v argocd >/dev/null 2>&1; then
  sudo curl -sSL -o /usr/local/bin/argocd \
    https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  sudo chmod +x /usr/local/bin/argocd
fi


# Ensure the argocd namespace exists
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd

# Add the Argo Helm repository and update the repo cache
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

# Install or upgrade the argo-cd release.  We set the service type to
# LoadBalancer so that an external endpoint is created automatically.
helm upgrade --install argo-cd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=LoadBalancer \
  --set configs.cm.create=true \
  --set configs.cm.name=argocd-cm \
  --set configs.rbac.create=true \
  --set configs.rbac.name=argocd-rbac-cm \
  --set configs.params.create=true \
  --set configs.params.name=argocd-cmd-params-cm \
  --set configs.tls.create=true --set configs.tls.name=argocd-tls-certs-cm \
  --set configs.knownHosts.create=true \
  --set configs.knownHosts.name=argocd-ssh-known-hosts-cm \
  --set configs.gpgKeys.create=true \
  --set configs.gpgKeys.name=argocd-gpg-keys-cm

# Wait for the Argo CD server deployment to become available
kubectl -n argocd rollout status deployment/argo-cd-argocd-server


echo "[END] Installing Argo CD CLI and Helm chart"
### END ### 
