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
3. Si usas imagenes distintas (v1/v2), valida que el comportamiento cambie tras `switch green` y regrese tras `switch blue`.

Nota didactica:
- Blue/Green requiere tener ambos entornos activos al mismo tiempo para poder conmutar y volver atras rapido.
