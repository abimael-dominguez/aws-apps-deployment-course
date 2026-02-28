# 5-canary-deployment

Prototipo didactico de Canary en ECS Fargate + ALB usando reparto de trafico por porcentaje.

## Que despliega
- 1 ALB publico
- 2 target groups (`stable`, `canary`)
- 2 servicios ECS Fargate (`app-stable`, `app-canary`)
- Listener HTTP con pesos configurables

## Archivos
- `deploy-canary.yml`
- `deploy.sh`

## Uso rapido
1. Ir a la carpeta:
   ```bash
   cd 5-canary-deployment
   chmod +x deploy.sh
   ```
2. Definir imagenes ECR (obligatorio):
   ```bash
   export IMAGE_URI_STABLE="111122223333.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:v1"
   export IMAGE_URI_CANARY="111122223333.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:v2"
   ```
3. Deploy inicial (95/5):
   ```bash
   ./deploy.sh deploy
   ```
4. Cambiar porcentaje gradualmente:
   ```bash
   ./deploy.sh set-weights 75 25
   ./deploy.sh set-weights 50 50
   ./deploy.sh set-weights 0 100
   ```
5. Rollback inmediato:
   ```bash
   ./deploy.sh rollback
   ```

## Como comprobar en practica
1. Ver pesos reales en ALB:
   ```bash
   ./deploy.sh status
   ```
2. Tomar el `ALB DNS` y lanzar varias peticiones:
   ```bash
   for i in {1..20}; do curl -s "http://<ALB_DNS>/whoami"; echo; done
   ```
3. Si usas imagenes distintas (v1/v2), valida funcionalmente tu endpoint de negocio y monitorea errores/latencia antes de subir porcentaje.

Nota didactica:
- Si `IMAGE_URI_STABLE` y `IMAGE_URI_CANARY` apuntan a la misma imagen, sirve para practicar el flujo de canary, pero no para validar diferencias funcionales entre versiones.

## Target Group vs. Servicio vs. Task

Target Group: es una colección lógica de endpoints (normalmente instancias EC2, IPs o tareas ECS registradas) a la que envía tráfico un balanceador de carga (ALB/NLB). Piensa en él como el “destino” al que el balanceador manda solicitudes; puede tener reglas de salud (health checks) y solo recibe tráfico si sus endpoints están saludables.
Servicio (ECS Service): en ECS representa una definición de cómo correr y mantener en ejecución una o más tareas basadas en una task definition. Controla cuántas tareas deben estar activas, las registra en un target group si lo necesitas, y puede hacer despliegues (rolling updates, blue/green, etc.). Es la entidad con la que se asegura que siempre haya la capacidad deseada.
Task (ECS Task): es la instancia real de ejecución. Parte de una task definition (que describe contenedores, recursos y permisos) y contiene los contenedores corriendo. Una tarea puede ser efímera (ada-hoc) o permanente cuando la gestiona un servicio.
En resumen: el servicio administra y mantiene tasks en ejecución; cada task ejecuta tus contenedores. El target group es el destino al que el balanceador dirige el tráfico para llegar a tus tasks (o instancias) saludables.
