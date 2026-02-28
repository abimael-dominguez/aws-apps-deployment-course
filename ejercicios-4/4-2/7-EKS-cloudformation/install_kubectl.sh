#!/usr/bin/env bash
set -euo pipefail

KUBECTL_VERSION="${KUBECTL_VERSION:-$(curl -fsSL https://dl.k8s.io/release/stable.txt)}"
ARCH="$(uname -m)"

case "$ARCH" in
  x86_64) K8S_ARCH="amd64" ;;
  aarch64|arm64) K8S_ARCH="arm64" ;;
  *)
    echo "ERROR: arquitectura no soportada: $ARCH" >&2
    exit 1
    ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Instalando kubectl ${KUBECTL_VERSION} para linux/${K8S_ARCH}..."
curl -fsSL -o "${TMP_DIR}/kubectl" \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl"
curl -fsSL -o "${TMP_DIR}/kubectl.sha256" \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl.sha256"

echo "$(cat "${TMP_DIR}/kubectl.sha256")  ${TMP_DIR}/kubectl" | sha256sum --check
chmod +x "${TMP_DIR}/kubectl"
sudo install -o root -g root -m 0755 "${TMP_DIR}/kubectl" /usr/local/bin/kubectl

echo "Instalacion completada:"
kubectl version --client
