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
