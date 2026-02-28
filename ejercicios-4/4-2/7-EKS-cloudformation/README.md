# 7-EKS-cloudformation (minimal, sin ALB)

Practica sencilla para desplegar la API del retail store en **EKS** usando **CloudFormation**, tomando como referencia la practica de ECS.

## Objetivo
- Crear un cluster EKS minimo con IaC (CloudFormation).
- Desplegar una app en Kubernetes usando una imagen que ya existe en ECR.
- Exponer la app sin ALB, usando `Service` tipo `NodePort`.

## EKS vs ECS (breve)
- **ECS**: mas simple de operar en AWS; integracion nativa muy directa; ideal para equipos que solo necesitan AWS.
- **EKS**: usas Kubernetes estandar; portabilidad y ecosistema CNCF (Helm, operators, etc.); ideal si quieres patrones multi-entorno o multi-cloud.
- Resumen rapido: ECS = simplicidad AWS, EKS = flexibilidad Kubernetes.

## Archivos de esta practica
- `deploy-eks-minimal.yml`: infraestructura base (VPC, IAM, EKS Cluster, Node Group).
- `setup_lab.sh`: automatiza deploy/delete y aplica manifiestos de Kubernetes.
- `install_kubectl.sh`: instala `kubectl` en Ubuntu AMI.

Defaults de costo minimo en esta version:
- `NODE_INSTANCE_TYPE=t3.micro`
- `DESIRED_SIZE=1`, `MIN_SIZE=1`, `MAX_SIZE=1`
- `REPLICAS=1`

## Prerrequisitos
Ejecuta en esta carpeta:

```bash
cd ejercicios-4/4-2/7-EKS-cloudformation
chmod +x setup_lab.sh install_kubectl.sh
```

## Instalacion de kubectl (Ubuntu AMI)
Si no tienes `kubectl`, instalalo con el script incluido:

```bash
./install_kubectl.sh
```

Respuesta esperada (ejemplo):
```text
Instalando kubectl v1.xx.x para linux/amd64...
/tmp/.../kubectl: OK
Instalacion completada:
Client Version: v1.xx.x
```

Verificacion rapida:

```bash
kubectl version --client
```

Verifica herramientas:

```bash
aws --version
kubectl version --client
aws sts get-caller-identity --profile data-engineer
```

Respuesta esperada (ejemplo):
```text
aws-cli/2.x.x
Client Version: v1.3x.x
{
  "Account": "123456789012",
  ...
}
```

## Paso a paso

## 1) (Opcional) Definir imagen ECR
Por defecto el script usa:
`894064921954.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest`

Si quieres otra imagen:

```bash
export IMAGE_URI="111122223333.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest"
```

## 2) Desplegar infraestructura + app

```bash
./setup_lab.sh deploy
```

Respuesta esperada (resumen):
```text
[1/5] Desplegando CloudFormation stack: eks-fastapi-minimal-stack
[2/5] Esperando cluster EKS activo
[3/5] Configurando kubeconfig
[4/5] Desplegando app en Kubernetes (Deployment + NodePort Service)
[5/5] Resultado
NAME                                READY   STATUS    ...
retail-store-api-xxxxxx-xxxxx       1/1     Running   ...

NAME                 TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
retail-store-api-svc NodePort   172.20.x.x      <none>        80:30080/TCP   ...
```

## 3) Verificar recursos Kubernetes

```bash
kubectl get nodes -o wide
kubectl -n retail get deploy,pods,svc
```

Respuesta esperada (resumen):
```text
NODES en estado Ready
Deployment retail-store-api con replicas disponibles
Service retail-store-api-svc tipo NodePort
```

## 4) Probar endpoints
Obtiene una IP publica de un nodo (de `kubectl get nodes -o wide`) y prueba:

```bash
NODE_IP="<IP_PUBLICA_DEL_NODO>"
curl "http://${NODE_IP}:30080/"
curl "http://${NODE_IP}:30080/whoami"
```

Respuesta esperada (ejemplo):
```text
{"message":"..."}
{"hostname":"retail-store-api-..."}
```

## URL de acceso: que link usar y como formarlo
En esta practica **no hay ALB**. El acceso es directo a un nodo EC2 del Node Group por `NodePort`.

Formula:
```text
http://<IP_PUBLICA_NODO>:<NODE_PORT>/
```

Con valores por defecto:
- `NODE_PORT=30080`
- URL base: `http://<IP_PUBLICA_NODO>:30080/`
- Endpoint `whoami`: `http://<IP_PUBLICA_NODO>:30080/whoami`

Como obtener la IP publica del nodo:
```bash
kubectl get nodes -o wide
```
Toma la columna `EXTERNAL-IP` y reemplazala en la URL.

Ejemplo completo:
```bash
NODE_IP="3.92.10.25"
curl "http://${NODE_IP}:30080/"
curl "http://${NODE_IP}:30080/whoami"
```

Si no responde:
- valida que el `Service` sea `NodePort` y exponga `30080`
- valida que el Security Group permita entrada TCP al `NODE_PORT`
- valida que el pod este en estado `Running`

## Como encontrarlo en la consola de AWS
Flujo recomendado en consola (region `us-east-1`):

1. CloudFormation:
   Busca el stack `eks-fastapi-minimal-stack` y revisa que este en `CREATE_COMPLETE`.
2. EKS:
   Entra a `Clusters` > `retail-eks-cluster` > pestaña `Compute` para confirmar el Node Group activo.
3. EC2:
   Ve a `Instances` y filtra por nodos del cluster (nombre similar a `eks-retail-eks-ng-*`).
4. EC2 (detalle de instancia):
   Abre una instancia nodo y copia su `Public IPv4 address`.
5. EC2 > Security Groups:
   Revisa el SG asociado a nodos/cluster y confirma regla de entrada TCP `30080` (o tu `NODE_PORT`) desde tu CIDR.
6. EKS (opcional):
   En `Workloads` valida que exista el deployment `retail-store-api` con pods `Running`.

Con eso, arma la URL:
```text
http://<Public-IPv4-address>:30080/whoami
```

## 5) Parametros utiles
Puedes ajustar en una sola linea:

```bash
NODE_PORT=30081 REPLICAS=1 DESIRED_SIZE=1 MIN_SIZE=1 MAX_SIZE=1 ./setup_lab.sh deploy
```

Variables comunes:
- `AWS_PROFILE`, `AWS_REGION`
- `STACK_NAME`, `CLUSTER_NAME`, `NODE_GROUP_NAME`
- `IMAGE_URI`
- `NODE_PORT`, `REPLICAS`

## 6) Eliminar todo

```bash
./setup_lab.sh delete
```

Respuesta esperada (resumen):
```text
Intentando borrar recursos Kubernetes...
Eliminando CloudFormation stack: eks-fastapi-minimal-stack
Stack eliminado.
```

## Troubleshooting rapido
- Si `kubectl` no conecta: ejecuta de nuevo `aws eks update-kubeconfig --name retail-eks-cluster --profile data-engineer --region us-east-1`.
- Si falla pull de imagen: valida `IMAGE_URI` y que el node role tenga `AmazonEC2ContainerRegistryReadOnly` (ya incluido en el template).
- Si no responde `curl`: revisa SG (`NodePort`) y que tomaste una IP publica de nodo correcta.

## Nota de costos
EKS y nodos EC2 generan costo. Ejecuta `./setup_lab.sh delete` al terminar la practica.

## Free Tier y creditos (importante)
- AWS Free Tier no siempre significa costo cero para EKS.
- EKS control plane se cobra por hora del cluster mientras exista.
- Para cuentas nuevas del programa actual (desde julio 2025), AWS indica hasta **USD 200** en creditos promocionales (normalmente USD 100 al crear cuenta + hasta USD 100 adicional por actividades), con ventana de uso limitada.
- Aun con creditos, si los agotas o no eres elegible, los cargos pasan a tarifa normal.
- Recomendacion: usa esta practica poco tiempo, borra con `./setup_lab.sh delete` y valida en Billing > Free Tier/Bills/Cost Explorer.
