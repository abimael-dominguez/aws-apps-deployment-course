# ECS Fargate + ALB + Auto Scaling (Proyecto Minimo)

Este README compara:

- `../3-ECS-ECR-Fargate-ALB-CloudFormation/deploy-ecs-fargate-alb.yml`
- `./deploy-ecs-fargate-alb-autoscaling.yml`

y explica como probar el auto scaling.

## 1) Diferencia entre ambos templates

## `deploy-ecs-fargate-alb.yml` (sin Auto Scaling)

- Crea infraestructura base: VPC, subnets publicas, IGW, route table, SG.
- Despliega ECS Fargate con ALB y Target Group.
- El numero de tareas se define fijo con `DesiredCount`.
- Si hay mas carga, **no** escala automaticamente.

## `deploy-ecs-fargate-alb-autoscaling.yml` (con Auto Scaling)

- Incluye todo lo anterior.
- Agrega recursos de Application Auto Scaling:
  - `AWS::ApplicationAutoScaling::ScalableTarget`
  - `AWS::ApplicationAutoScaling::ScalingPolicy`
- Define limites:
  - `MinCapacity` (minimo de tareas)
  - `MaxCapacity` (maximo de tareas)
- Usa politica de target tracking por CPU:
  - `ECSServiceAverageCPUUtilization`
  - `TargetValue: 50.0`

En resumen:
- Sin autoscaling: capacidad fija.
- Con autoscaling: capacidad dinamica segun uso de CPU.

## 2) A que DNS/endpoint apuntar

Apunta al DNS publico del ALB de la stack con autoscaling:

```bash
aws --profile data-engineer --region us-east-1 cloudformation describe-stacks \
  --stack-name ecs-fastapi-autoscaling-stack \
  --query "Stacks[0].Outputs[?OutputKey=='ALBPublicDNS'].OutputValue" \
  --output text
```

Guarda ese valor:

```bash
ALB_DNS="<DNS_DEL_OUTPUT>"
echo "http://${ALB_DNS}/"
echo "http://${ALB_DNS}/whoami"
```

Endpoints utiles:

- `GET /` prueba basica.
- `GET /whoami` devuelve hostname del contenedor (sirve para ver balanceo).
- `GET /items/1?count=2` endpoint funcional adicional.

## 3) Despliegue del stack con autoscaling

Desde esta carpeta:

```bash
./deploy.sh deploy
```

Nota sobre imagen ECR:

- El script usa por defecto `dev/fastapi-repo:latest`.
- URI esperada por defecto:
  `894064921954.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest`

Si quieres forzar una imagen especifica:

```bash
IMAGE_URI=894064921954.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest ./deploy.sh deploy
```

Opcional (proyecto mas minimo):

```bash
MIN_CAPACITY=1 MAX_CAPACITY=3 ./deploy.sh deploy
```

## 4) Probar balanceo (ALB distribuyendo trafico)

Haz multiples requests a `/whoami`:

```bash
for i in {1..30}; do
  curl -s "http://${ALB_DNS}/whoami"
  echo
done
```

Si hay mas de una tarea corriendo, deberias ver hostnames distintos.

## 5) Probar auto scaling (subida de tareas)

Importante: con trafico ligero, puede no subir CPU suficiente. Necesitas carga sostenida.

## Opcion A: con `hey` (si lo tienes instalado)

```bash
hey -z 3m -c 200 "http://${ALB_DNS}/"
```

## Opcion B: solo bash + curl (sin instalar nada)

```bash
for n in {1..20}; do
  (
    for i in {1..2000}; do
      curl -s "http://${ALB_DNS}/" >/dev/null
    done
  ) &
done
wait
```

## Monitorear el escalado en paralelo

Primero identifica cluster y service:

```bash
aws --profile data-engineer --region us-east-1 cloudformation describe-stacks \
  --stack-name ecs-fastapi-autoscaling-stack \
  --query "Stacks[0].Outputs[?OutputKey=='ClusterName' || OutputKey=='ServiceName'].[OutputKey,OutputValue]" \
  --output table
```

Luego observa `desiredCount` y `runningCount`:

```bash
watch -n 10 'aws --profile data-engineer --region us-east-1 ecs describe-services \
  --cluster fastapi-ecs-cluster \
  --services fastapi-service \
  --query "services[0].{desired:desiredCount,running:runningCount,pending:pendingCount}" \
  --output table'
```

Tambien puedes revisar el target de autoscaling:

```bash
aws --profile data-engineer --region us-east-1 application-autoscaling describe-scalable-targets \
  --service-namespace ecs \
  --resource-ids service/fastapi-ecs-cluster/fastapi-service \
  --output table
```

## 6) Que deberias notar

- Inicio: `desiredCount = MinCapacity`.
- Bajo carga sostenida: `desiredCount` sube (hasta `MaxCapacity`).
- Al bajar la carga: despues del cooldown, el servicio reduce tareas.

No esperes cambio instantaneo: hay latencia normal por metricas, evaluacion de politica y arranque de tareas.

## 7) Limpieza

```bash
./deploy.sh delete
```
