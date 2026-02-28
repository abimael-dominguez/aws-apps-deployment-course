# 5-3-cifrado-roles-backups-minimal (30 min)

Practica corta y automatizada para cubrir:
- Cifrado en reposo (S3 + KMS: Key Management Service, servicio para crear y administrar llaves de cifrado)
- Rol IAM de minimo privilegio
- Backup y restore con validacion por hash

Compatible con `AWS Free Tier` (S3 + IAM) y usando tu contexto:
- `--profile data-engineer`
- `us-east-1`

## Objetivo de la practica
Implementar una base minima de seguridad operativa en AWS que puedas reutilizar en proyectos reales:
- proteger datos en reposo con cifrado administrado (KMS)
- limitar accesos con principio de minimo privilegio (IAM Role + Policy)
- asegurar recuperacion de datos con un flujo probado de backup y restore

Al terminar, no solo tendras recursos creados, sino evidencia de que:
- el backup queda cifrado
- el acceso esta acotado a lo necesario
- la restauracion recupera exactamente la informacion original

## Casos de uso reales
Estas practicas se usan cuando:
- manejas datos sensibles (clientes, pagos, PII, datos internos)
- necesitas cumplir auditorias o controles (ISO 27001, SOC 2, politicas internas)
- operas pipelines de datos/ML y quieres evitar perdida de informacion ante errores de despliegue
- haces despliegues frecuentes (canary/blue-green) y requieres rollback de datos confiable
- trabajas en equipos donde cada servicio debe tener permisos separados por entorno (`dev`, `stg`, `prod`)

## Archivos
- `generate_dummy_data.sh`
- `setup_lab.sh`
- `backup_restore.sh`
- `cleanup_lab.sh`

## Tiempo estimado
- Setup: 10-15 min
- Backup + restore: 5-10 min
- Evidencias + cleanup: 5 min

Total: ~30 min

## Prerrequisitos
```bash
aws --version
aws sts get-caller-identity --profile data-engineer
```

Salida esperada (ejemplo):
```text
aws-cli/2.x.x ...
{
  "Account": "123456789012",
  ...
}
```

## Quickstart (3 comandos)
Desde esta carpeta:
```bash
cd ejercicios-5/5-3-cifrado-roles-backups-minimal
chmod +x *.sh

./setup_lab.sh
./backup_restore.sh
./cleanup_lab.sh
```

## Que hace cada script
### 1) `./setup_lab.sh`
Automatiza:
- genera datos dummy (`data/customers.json`)
- crea KMS key + alias
- crea bucket S3 con versionado y cifrado por defecto KMS
- crea rol IAM con policy inline de minimo privilegio para `backups/*`
- guarda estado en `.lab.env`

Salida esperada (resumen):
```text
[1/6] Generando datos dummy...
...
Listo. Recursos creados:
- Bucket: seg-lab-...
- KMS Key: ...
- Role ARN: arn:aws:iam::...:role/seguridad-backup-role-...
- Estado: .../.lab.env
```

### 2) `./backup_restore.sh`
Automatiza:
- sube backup cifrado con KMS a `s3://<bucket>/backups/...`
- restaura archivo a `restore/...`
- compara `sha256` original vs restaurado

Salida esperada (resumen):
```text
OK
- SSE: aws:kms
- Backup key: backups/customers-....json
- Restore file: restore/customers-restored-....json
- SHA256: <hash>
```

### 3) `./cleanup_lab.sh`
Automatiza:
- borra versiones y delete markers del bucket
- elimina bucket
- elimina role policy + rol
- programa borrado de KMS key (7 dias, minimo AWS)
- borra `.lab.env`

Salida esperada (resumen):
```text
Limpieza completa.
- Bucket eliminado: seg-lab-...
- Rol eliminado: seguridad-backup-role-...
- KMS key en borrado programado (7 dias): ...
```

## Evidencias para entregar
- Confirmacion de bucket cifrado con KMS (salida de setup).
- Confirmacion de rol IAM creado (Role ARN).
- Confirmacion de backup cifrado (`SSE: aws:kms`).
- Confirmacion de restore valido (mismo `SHA256`).

## Nota didactica: por que el JSON sigue siendo legible
En esta practica usamos **cifrado en reposo del lado de AWS** (SSE-KMS en S3).
Eso significa:
- el objeto se guarda cifrado dentro de S3
- cuando lo descargas con permisos correctos, AWS lo descifra y lo recibes en texto normal

Por eso `data/customers.json` y `restore/customers-restored-...json` se ven legibles.
No es un error: es el comportamiento esperado de SSE-KMS.

Puedes comprobar que el objeto en S3 si esta cifrado con:
```bash
source .lab.env
aws s3api head-object \
  --bucket "$BUCKET_NAME" \
  --key "$BACKUP_KEY" \
  --profile "$AWS_PROFILE" \
  --query '{SSE:ServerSideEncryption,KMS:SSEKMSKeyId}'
```

Salida esperada (resumen):
```text
{
  "SSE": "aws:kms",
  "KMS": "arn:aws:kms:us-east-1:...:key/..."
}
```

Si quieres que el archivo tambien sea ilegible fuera de S3, necesitas **cifrado del lado cliente** (cifrar antes de subir).

## Variables opcionales
Si necesitas cambiar defaults:
```bash
export AWS_PROFILE=data-engineer
export AWS_REGION=us-east-1
export LAB_ID=20260228170000   # opcional, para nombre fijo de recursos
```

## Troubleshooting rapido
- `AccessDenied`: tu usuario del perfil no tiene permisos IAM/KMS/S3 suficientes.
- `BucketAlreadyExists`: reintenta con otro `LAB_ID`.
- `No existe .lab.env`: corre primero `./setup_lab.sh`.

## Nota de costos
- S3 + IAM suelen ser costo muy bajo para esta practica.
- KMS puede generar costo segun tu cuenta/uso.
- Ejecuta `./cleanup_lab.sh` al terminar.
