# 6-blue-green-deployment

Prototipo didactico de Blue/Green en ECS Fargate + ALB con cambio total de trafico.

## Que despliega
- 1 ALB publico
- 2 target groups (`blue`, `green`)
- 2 servicios ECS Fargate (`app-blue`, `app-green`)
- Listener HTTP con trafico al 100% hacia un color activo

## Archivos
- `deploy-blue-green.yml`
- `deploy.sh`

## Uso rapido
1. Ir a la carpeta:
   ```bash
   cd 6-blue-green-deployment
   chmod +x deploy.sh
   ```
2. Definir imagenes ECR:
   ```bash
   export IMAGE_URI_BLUE="111122223333.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:v1"
   export IMAGE_URI_GREEN="111122223333.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:v2"
   ```
3. Deploy inicial (trafico en blue):
   ```bash
   ./deploy.sh deploy
   ```
4. Cambiar trafico a green:
   ```bash
   ./deploy.sh switch green
   ```
5. Rollback rapido a blue:
   ```bash
   ./deploy.sh switch blue
   ```

## Como comprobar en practica
1. Ver ALB y color activo:
   ```bash
   ./deploy.sh status
   ```
2. Probar endpoint:
   ```bash
   curl -s "http://<ALB_DNS>/"
   curl -s "http://<ALB_DNS>/whoami"
   ```

4. O lanzar varias peticiones:
   ```bash
   for i in {1..20}; do curl -s "http://<ALB_DNS>/whoami"; echo; done
   ```
  
3. Si usas imagenes distintas (v1/v2), valida que el comportamiento cambie tras `switch green` y regrese tras `switch blue`.

Nota didactica:
- Blue/Green requiere tener ambos entornos activos al mismo tiempo para poder conmutar y volver atras rapido.


## Conceptos clave

- **Task Definition**
  Plantilla de ejecucion del contenedor: imagen (modelo/API), CPU/memoria, puertos, variables, logs y roles IAM.

- **Task (ECS Task)**
  Instancia real corriendo desde una task definition. Aqui vive tu endpoint de inferencia en ejecucion.

- **Servicio (ECS Service)**
  Controla cuantas tasks deben estar activas (`desired count`), las reemplaza si fallan y las registra en target groups.

- **Target Group**
  Conjunto de endpoints (IP/tasks) a los que ALB envia trafico. Solo enruta a los que pasan health checks.

- **Listener / reglas del ALB**
  Punto de entrada HTTP/HTTPS. Decide a que target group enviar trafico (100/0 en blue-green, 95/5 o similar en canary).

- **Health Checks**
  Sonda de salud del ALB (ej: `/`). Si falla, esa task deja de recibir requests. Es clave para evitar serving degradado.

- **Estrategia de despliegue**
  `Canary`: subes porcentaje gradualmente y validas metricas.  
  `Blue/Green`: cambias 100% de trafico entre dos entornos y haces rollback rapido.

**Resumen operativo:**  
`Task Definition -> Tasks -> ECS Service -> Target Group -> ALB Listener -> Usuario`  
Para ML, piensa en esto como un pipeline de serving versionado: despliegas una nueva version de modelo/API, observas `error rate`, `latencia p95/p99` y consumo, y solo entonces aumentas trafico.
