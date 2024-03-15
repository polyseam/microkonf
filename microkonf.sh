#!/bin/bash

# Ensure MICROK8S_HOST is set
if [ -z "$MICROK8S_HOST" ]; then
  echo "Error: MICROK8S_HOST environment variable is not set."
  exit 1
fi

# Check if the MICROK8S_HOST cluster is already configured
existing_clusters=$(kubectl config get-clusters)
cluster_name="microk8s-cluster" # Example cluster name format

if echo "$existing_clusters" | grep -q "$cluster_name"; then
  # Direct the prompt to /dev/tty to ensure it's displayed in the terminal
  sleep 5
  read -p "Cluster $cluster_name is already configured. Replace? (y/n): " choice </dev/tty
  case "$choice" in
    y|Y )
      echo "Proceeding to replace the cluster configuration..."
      kubectl config delete-cluster "$cluster_name"
      kubectl config delete-user "admin"
      ;;
    * )
      echo "Exiting without making changes."
      exit 0
      ;;
  esac
fi

# Read kubeconfig from stdin into a temporary file
KUBECONFIG_MODIFIED=$(mktemp)
cat > "$KUBECONFIG_MODIFIED"

# Modify the kubeconfig file using awk
awk -v hostname="$MICROK8S_HOST" '
BEGIN {skipCA=0; replacedServer=0; addedInsecure=0}
/clusters:/ {inCluster=1}
inCluster && /- cluster:/ {clusterCount++}
inCluster && clusterCount==1 && /server:/ && !replacedServer {
    print "    server: https://"hostname":16443"
    replacedServer=1
    next
}
inCluster && clusterCount==1 && replacedServer && !addedInsecure {
    print "    insecure-skip-tls-verify: true"
    addedInsecure=1
}
inCluster && clusterCount==1 && /certificate-authority-data:/ && !skipCA {
    skipCA=1
    next
}
{print}
' "$KUBECONFIG_MODIFIED" > "${KUBECONFIG_MODIFIED}_tmp" && mv "${KUBECONFIG_MODIFIED}_tmp" "$KUBECONFIG_MODIFIED"

# Merge the modified kubeconfig with the existing one and output to a temporary file
MERGED_KUBECONFIG=$(mktemp)
KUBECONFIG="$HOME/.kube/config:$KUBECONFIG_MODIFIED" kubectl config view --merge --flatten > "$MERGED_KUBECONFIG"

# Backup the original kubeconfig file
cp "$HOME/.kube/config" "$HOME/.kube/config.backup.$(date +%Y%m%d%H%M%S)"

# Overwrite the original kubeconfig file with the merged configuration
cp "$MERGED_KUBECONFIG" "$HOME/.kube/config"

# Clean up
rm -f "$KUBECONFIG_MODIFIED" "$MERGED_KUBECONFIG"

echo "Kubeconfig merged and updated successfully."
