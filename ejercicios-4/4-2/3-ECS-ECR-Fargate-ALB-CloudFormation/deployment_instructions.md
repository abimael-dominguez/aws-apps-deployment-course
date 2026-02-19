# Migración de la práctica ECR + ECS (consola) a IaC con CloudFormation (FARGATE)

Esta entrega incluye:
- `deploy-ecs-fargate.yml` : plantilla CloudFormation parametrizada.
- `deploy.sh` : script para deploy/delete y espera (parámetros 'deploy' y 'delete').

## Archivos incluidos
- deploy-ecs-fargate.yml
- deploy.sh

## Variables de entorno (docstring resumido)
- AWS_REGION      -> Región AWS donde desplegar (ej: us-west-2)
- ACCOUNT_ID      -> ID de la cuenta AWS (ej: 111122223333)
- REPO_NAME       -> Nombre del repositorio ECR
- IMAGE_TAG       -> Tag de la imagen (ej: latest)
- IMAGE_URI       -> URI completa de la imagen (si no se define, el script la compone automáticamente)
- STACK_NAME      -> Nombre del stack CloudFormation
- CONTAINER_PORT  -> Puerto que expone la app (ej: 8000)
- ALLOWED_CIDR    -> CIDR permitido en el Security Group (ej: 0.0.0.0/0)
- TASK_CPU        -> CPU para la tarea (256=0.25vCPU)
- TASK_MEMORY     -> Memoria (MB) para la tarea (512=0.5GB)
- DESIRED_COUNT   -> Número de tareas en el Service

## Uso rápido
1. Haz ejecutable: `chmod +x deploy.sh`
2. Opcional: exporta variables de entorno para personalizar
3. Deploy: `./deploy.sh deploy`
4. Delete: `./deploy.sh delete`

## Notas
- El script usa `aws cloudformation deploy` para crear/actualizar la pila y `aws cloudformation wait` para esperar a que termine.
- Si usas la ECR que crea la pila, sube la imagen **después** de crear la pila o define IMAGE_URI apuntando a tu repo externo.
