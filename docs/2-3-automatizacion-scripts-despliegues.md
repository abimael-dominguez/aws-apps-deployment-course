# Automatización con Scripts y Despliegues Reproducibles

Convertir comandos manuales en un **script reproducible** que:

- **Reproducible**: mismo resultado hoy y mañana.
- **Idempotente**: `aws cloudformation deploy` hace create/update automáticamente.
- **Automatizable**: funciona igual desde tu laptop o un pipeline CI.

## Archivos del ejercicio

- Script: [ejercicios-2/2-3/deploy-stack/deploy-stack.sh](ejercicios-2/2-3/deploy-stack/deploy-stack.sh)
- Template: [ejercicios-2/2-3/deploy-stack/1-ec2-template.yml](ejercicios-2/2-3/deploy-stack/1-ec2-template.yml)

## Prerrequisitos

1. AWS CLI configurada con credenciales válidas.
2. Variables de entorno configuradas:

```bash
cd ejercicios-2/2-3/deploy-stack
cp .env.example .env   # edita con tus valores
source .env
```

## Uso del script

```bash
chmod +x ./deploy-stack.sh

# Crear o actualizar el stack
./deploy-stack.sh apply

# Ver estado del stack
./deploy-stack.sh status

# Eliminar el stack
./deploy-stack.sh delete
```

## ¿Qué hace reproducible este flujo?

1. **Un solo punto de entrada**: `deploy-stack.sh`
2. **Variables de entorno**: controlan región, perfil y nombre del stack
3. **Idempotencia**: `aws cloudformation deploy` detecta si debe crear o actualizar

## Troubleshooting

```bash
# Verificar credenciales
aws sts get-caller-identity

# Ver eventos del stack (útil si falla)
aws cloudformation describe-stack-events \
  --stack-name "$STACK_NAME" \
  --max-items 10
```
