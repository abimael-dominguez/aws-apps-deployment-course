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
   # ./deploy.sh set-weights <stable-weight> <canary-weight>
   ./deploy.sh set-weights 75 25
   ./deploy.sh set-weights 50 50
   ./deploy.sh set-weights 0 100
   ```
5. Rollback inmediato:
   ```bash
   # Implies stable-weight=100 canary-weight=0
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

## Mapa de conceptos clave (para ML engineers)

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
