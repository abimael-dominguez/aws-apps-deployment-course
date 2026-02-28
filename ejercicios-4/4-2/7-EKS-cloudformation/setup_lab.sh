#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-data-engineer}"
AWS_REGION="${AWS_REGION:-us-east-1}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEMPLATE_FILE="${TEMPLATE_FILE:-$BASE_DIR/deploy-eks-minimal.yml}"
STACK_NAME="${STACK_NAME:-eks-fastapi-minimal-stack}"
CLUSTER_NAME="${CLUSTER_NAME:-retail-eks-cluster}"
NODE_GROUP_NAME="${NODE_GROUP_NAME:-retail-eks-ng}"
K8S_VERSION="${K8S_VERSION:-1.30}"
NODE_INSTANCE_TYPE="${NODE_INSTANCE_TYPE:-t3.micro}"
DESIRED_SIZE="${DESIRED_SIZE:-1}"
MIN_SIZE="${MIN_SIZE:-1}"
MAX_SIZE="${MAX_SIZE:-1}"
ALLOWED_CIDR="${ALLOWED_CIDR:-0.0.0.0/0}"

APP_NAMESPACE="${APP_NAMESPACE:-retail}"
APP_NAME="${APP_NAME:-retail-store-api}"
IMAGE_URI="${IMAGE_URI:-894064921954.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest}"
CONTAINER_PORT="${CONTAINER_PORT:-8000}"
SERVICE_PORT="${SERVICE_PORT:-80}"
NODE_PORT="${NODE_PORT:-30080}"
REPLICAS="${REPLICAS:-1}"

usage() {
  cat <<EOF
Uso: ./setup_lab.sh <deploy|delete|help>

Variables opcionales:
  AWS_PROFILE, AWS_REGION
  STACK_NAME, CLUSTER_NAME, NODE_GROUP_NAME, K8S_VERSION
  NODE_INSTANCE_TYPE, DESIRED_SIZE, MIN_SIZE, MAX_SIZE, ALLOWED_CIDR
  IMAGE_URI, APP_NAMESPACE, APP_NAME, CONTAINER_PORT, SERVICE_PORT, NODE_PORT, REPLICAS

Ejemplos:
  ./setup_lab.sh deploy
  IMAGE_URI=111122223333.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest ./setup_lab.sh deploy
  ./setup_lab.sh delete
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: no se encontro el comando '$1'" >&2
    exit 1
  }
}

require_file() {
  [[ -f "$1" ]] || {
    echo "ERROR: no existe el archivo '$1'" >&2
    exit 1
  }
}

deploy_stack() {
  require_cmd aws
  require_cmd kubectl
  require_file "$TEMPLATE_FILE"

  echo "[1/5] Desplegando CloudFormation stack: $STACK_NAME"
  aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-file "$TEMPLATE_FILE" \
    --parameter-overrides \
      ClusterName="$CLUSTER_NAME" \
      NodeGroupName="$NODE_GROUP_NAME" \
      KubernetesVersion="$K8S_VERSION" \
      NodeInstanceType="$NODE_INSTANCE_TYPE" \
      DesiredSize="$DESIRED_SIZE" \
      MinSize="$MIN_SIZE" \
      MaxSize="$MAX_SIZE" \
      AllowedCidr="$ALLOWED_CIDR" \
      NodePort="$NODE_PORT" \
    --no-fail-on-empty-changeset

  echo "[2/5] Esperando cluster EKS activo"
  aws --profile "$AWS_PROFILE" --region "$AWS_REGION" eks wait cluster-active --name "$CLUSTER_NAME"

  echo "[3/5] Configurando kubeconfig"
  aws --profile "$AWS_PROFILE" --region "$AWS_REGION" eks update-kubeconfig --name "$CLUSTER_NAME"

  echo "[4/5] Desplegando app en Kubernetes (Deployment + NodePort Service)"
  kubectl get namespace "$APP_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$APP_NAMESPACE"

  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  namespace: ${APP_NAMESPACE}
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
    spec:
      containers:
        - name: ${APP_NAME}
          image: ${IMAGE_URI}
          ports:
            - containerPort: ${CONTAINER_PORT}
---
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}-svc
  namespace: ${APP_NAMESPACE}
spec:
  type: NodePort
  selector:
    app: ${APP_NAME}
  ports:
    - protocol: TCP
      port: ${SERVICE_PORT}
      targetPort: ${CONTAINER_PORT}
      nodePort: ${NODE_PORT}
EOF

  kubectl -n "$APP_NAMESPACE" rollout status deployment "$APP_NAME" --timeout=180s

  echo "[5/5] Resultado"
  kubectl -n "$APP_NAMESPACE" get pods -o wide
  kubectl -n "$APP_NAMESPACE" get svc "$APP_NAME-svc"

  NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || true)
  if [[ -n "$NODE_IP" ]]; then
    echo
    echo "API accesible (si SG y app estan OK):"
    echo "http://${NODE_IP}:${NODE_PORT}/"
    echo "http://${NODE_IP}:${NODE_PORT}/whoami"
  else
    echo
    echo "No se pudo obtener ExternalIP automaticamente."
    echo "Consulta con: kubectl get nodes -o wide"
  fi
}

delete_stack() {
  require_cmd aws

  echo "Intentando borrar recursos Kubernetes (si el cluster responde)..."
  if aws --profile "$AWS_PROFILE" --region "$AWS_REGION" eks describe-cluster --name "$CLUSTER_NAME" >/dev/null 2>&1; then
    aws --profile "$AWS_PROFILE" --region "$AWS_REGION" eks update-kubeconfig --name "$CLUSTER_NAME" >/dev/null 2>&1 || true
    kubectl -n "$APP_NAMESPACE" delete service "$APP_NAME-svc" --ignore-not-found=true >/dev/null 2>&1 || true
    kubectl -n "$APP_NAMESPACE" delete deployment "$APP_NAME" --ignore-not-found=true >/dev/null 2>&1 || true
  fi

  echo "Eliminando CloudFormation stack: $STACK_NAME"
  aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation delete-stack --stack-name "$STACK_NAME"
  aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"
  echo "Stack eliminado."
}

main() {
  case "${1:-}" in
    deploy) deploy_stack ;;
    delete) delete_stack ;;
    help|-h|--help|"") usage ;;
    *)
      echo "ERROR: comando desconocido: ${1}" >&2
      usage
      exit 2
      ;;
  esac
}

main "$@"
