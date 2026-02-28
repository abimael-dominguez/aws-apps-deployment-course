# Gestión de Identidades con IAM: Usuarios, Roles, Políticas

## Introducción

IAM (Identity and Access Management) es el servicio de AWS que permite gestionar de forma segura el acceso a los recursos de AWS. Es fundamental para implementar el principio de menor privilegio y mantener la seguridad de tu infraestructura.

## Conceptos Fundamentales

### 1. Usuarios (Users)

Un usuario de IAM es una identidad dentro de tu cuenta AWS con credenciales permanentes:
- Representa una persona o aplicación
- Tiene credenciales de acceso únicas (contraseña y/o claves de acceso)
- Puede pertenecer a múltiples grupos
- Se le pueden asignar políticas directamente

### 2. Grupos (Groups)

Conjunto de usuarios de IAM:
- Facilita la gestión de permisos para múltiples usuarios
- Las políticas se asignan al grupo, no a usuarios individuales
- Un usuario puede pertenecer a varios grupos
- Los permisos son acumulativos

### 3. Roles (Roles)

Identidad con permisos temporales:
- **No** tiene credenciales permanentes
- Puede ser asumido por usuarios, servicios o cuentas de AWS
- Útil para delegar acceso sin compartir credenciales
- Ideal para servicios de AWS (EC2, Lambda, ECS)

### 4. Políticas (Policies)

Documentos JSON que definen permisos:
- **Políticas gestionadas por AWS**: Creadas y mantenidas por AWS
- **Políticas gestionadas por el cliente**: Creadas por ti
- **Políticas en línea**: Adjuntas directamente a un usuario, grupo o rol

## Estructura de una Política IAM

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::mi-bucket/*"
    }
  ]
}
```

**Elementos clave:**
- `Effect`: `Allow` o `Deny`
- `Action`: Operaciones permitidas/denegadas
- `Resource`: Recursos de AWS afectados
- `Condition`: (Opcional) Condiciones adicionales

## Comandos AWS CLI - Usuarios

### Listar usuarios

```bash
# Listar todos los usuarios
aws iam list-users

# Formato tabla
aws iam list-users --output table

# Solo nombres de usuarios
aws iam list-users --query "Users[].UserName" --output text
```

### Crear un usuario

```bash
# Crear usuario
aws iam create-user --user-name developer-juan

# Crear usuario con tags
aws iam create-user --user-name developer-maria --tags Key=Department,Value=Engineering Key=Project,Value=WebApp
```

### Gestionar credenciales

```bash
# Crear claves de acceso para un usuario
aws iam create-access-key --user-name developer-juan

# Listar claves de acceso de un usuario
aws iam list-access-keys --user-name developer-juan

# Desactivar una clave de acceso
aws iam update-access-key --user-name developer-juan --access-key-id AKIAIOSFODNN7EXAMPLE --status Inactive

# Eliminar una clave de acceso
aws iam delete-access-key --user-name developer-juan --access-key-id AKIAIOSFODNN7EXAMPLE
```

### Crear contraseña de consola

```bash
# Crear contraseña para acceso a la consola
aws iam create-login-profile --user-name developer-juan --password "TempPassword123!" --password-reset-required

# Actualizar contraseña
aws iam update-login-profile --user-name developer-juan --password "NewPassword456!"
```

### Eliminar usuario

```bash
# Eliminar usuario (primero remover todas las políticas y credenciales)
aws iam delete-user --user-name developer-juan
```

## Comandos AWS CLI - Grupos

### Gestionar grupos

```bash
# Crear grupo
aws iam create-group --group-name Developers

# Listar grupos
aws iam list-groups

# Agregar usuario a grupo
aws iam add-user-to-group --user-name developer-juan --group-name Developers

# Listar usuarios en un grupo
aws iam get-group --group-name Developers

# Remover usuario de grupo
aws iam remove-user-from-group --user-name developer-juan --group-name Developers

# Eliminar grupo
aws iam delete-group --group-name Developers
```

## Comandos AWS CLI - Roles

### Crear un rol

```bash
# Crear documento de confianza (trust policy)
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Crear el rol
aws iam create-role --role-name EC2-S3-Access-Role --assume-role-policy-document file://trust-policy.json
```

### Listar y gestionar roles

```bash
# Listar todos los roles
aws iam list-roles

# Obtener detalles de un rol específico
aws iam get-role --role-name EC2-S3-Access-Role

# Listar roles con un prefijo específico
aws iam list-roles --query "Roles[?starts_with(RoleName, 'EC2')].RoleName"

# Eliminar rol
aws iam delete-role --role-name EC2-S3-Access-Role
```

## Comandos AWS CLI - Políticas

### Listar políticas

```bash
# Listar políticas gestionadas por AWS
aws iam list-policies --scope AWS

# Listar políticas del cliente
aws iam list-policies --scope Local

# Buscar política específica
aws iam list-policies --query "Policies[?PolicyName=='AmazonS3ReadOnlyAccess']"
```

### Crear política personalizada

```bash
# Crear archivo de política
cat > s3-read-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-app-bucket",
        "arn:aws:s3:::my-app-bucket/*"
      ]
    }
  ]
}
EOF

# Crear la política
aws iam create-policy --policy-name S3ReadOnlyCustom --policy-document file://s3-read-policy.json
```

### Adjuntar políticas

```bash
# Adjuntar política a un usuario
aws iam attach-user-policy --user-name developer-juan --policy-arn arn:aws:iam::123456789012:policy/S3ReadOnlyCustom

# Adjuntar política a un grupo
aws iam attach-group-policy --group-name Developers --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Adjuntar política a un rol
aws iam attach-role-policy --role-name EC2-S3-Access-Role --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### Listar políticas adjuntas

```bash
# Políticas adjuntas a un usuario
aws iam list-attached-user-policies --user-name developer-juan

# Políticas adjuntas a un grupo
aws iam list-attached-group-policies --group-name Developers

# Políticas adjuntas a un rol
aws iam list-attached-role-policies --role-name EC2-S3-Access-Role
```

### Desadjuntar políticas

```bash
# Desadjuntar política de usuario
aws iam detach-user-policy --user-name developer-juan --policy-arn arn:aws:iam::123456789012:policy/S3ReadOnlyCustom

# Desadjuntar política de grupo
aws iam detach-group-policy --group-name Developers --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Desadjuntar política de rol
aws iam detach-role-policy --role-name EC2-S3-Access-Role --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

## Ejemplo Práctico: Configuración Completa

```bash
#!/bin/bash
# Script para crear un usuario con permisos S3

USER_NAME="app-developer"
GROUP_NAME="S3-Developers"
POLICY_NAME="AppS3Access"

# 1. Crear grupo
echo "Creando grupo ${GROUP_NAME}..."
aws iam create-group --group-name ${GROUP_NAME}

# 2. Crear política personalizada
echo "Creando política ${POLICY_NAME}..."
cat > policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::app-data-bucket",
        "arn:aws:s3:::app-data-bucket/*"
      ]
    }
  ]
}
EOF

POLICY_ARN=$(aws iam create-policy --policy-name ${POLICY_NAME} --policy-document file://policy.json --query 'Policy.Arn' --output text)
echo "Política creada: ${POLICY_ARN}"

# 3. Adjuntar política al grupo
echo "Adjuntando política al grupo..."
aws iam attach-group-policy --group-name ${GROUP_NAME} --policy-arn ${POLICY_ARN}

# 4. Crear usuario
echo "Creando usuario ${USER_NAME}..."
aws iam create-user --user-name ${USER_NAME}

# 5. Agregar usuario al grupo
echo "Agregando usuario al grupo..."
aws iam add-user-to-group --user-name ${USER_NAME} --group-name ${GROUP_NAME}

# 6. Crear claves de acceso
echo "Generando claves de acceso..."
aws iam create-access-key --user-name ${USER_NAME} > credentials.json

echo "\n=== Configuración completada ==="
echo "Usuario: ${USER_NAME}"
echo "Grupo: ${GROUP_NAME}"
echo "Política: ${POLICY_NAME}"
echo "Credenciales guardadas en: credentials.json"

# Limpiar
rm policy.json
```

## Mejores Prácticas

### 1. Principio de Menor Privilegio
- Otorga solo los permisos necesarios
- Revisa y audita permisos regularmente
- Usa políticas específicas en lugar de `*`

### 2. Usar Roles en lugar de Usuarios para Servicios
```bash
# ✅ Correcto: Asignar rol a instancia EC2
aws iam create-role --role-name EC2AppRole --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name EC2AppRole --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# ❌ Incorrecto: Hardcodear credenciales de usuario en EC2
```

### 3. Habilitar MFA (Multi-Factor Authentication)
```bash
# Crear dispositivo MFA virtual
aws iam create-virtual-mfa-device --virtual-mfa-device-name root-account-mfa --outfile QRCode.png --bootstrap-method QRCodePNG

# Habilitar MFA para usuario
aws iam enable-mfa-device --user-name admin-user --serial-number arn:aws:iam::123456789012:mfa/root-account-mfa --authentication-code-1 123456 --authentication-code-2 789012
```

### 4. Rotar Credenciales Regularmente
```bash
# Listar edad de claves de acceso
aws iam list-access-keys --user-name developer-juan --query 'AccessKeyMetadata[].[AccessKeyId,CreateDate]'

# Crear nueva clave antes de eliminar la antigua
aws iam create-access-key --user-name developer-juan
# Actualizar aplicaciones con nueva clave
aws iam delete-access-key --user-name developer-juan --access-key-id OLD_KEY_ID
```

### 5. Usar Grupos para Gestión de Permisos
```bash
# ✅ Gestionar permisos a nivel de grupo
aws iam attach-group-policy --group-name Developers --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# ❌ Evitar asignar políticas directamente a usuarios individuales
```

### 6. Políticas Basadas en Condiciones
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "203.0.113.0/24"
        },
        "DateGreaterThan": {
          "aws:CurrentTime": "2024-01-01T00:00:00Z"
        },
        "DateLessThan": {
          "aws:CurrentTime": "2024-12-31T23:59:59Z"
        }
      }
    }
  ]
}
```

## Auditoría y Monitoreo

```bash
# Ver último uso de una clave de acceso
aws iam get-access-key-last-used --access-key-id AKIAIOSFODNN7EXAMPLE

# Generar reporte de credenciales
aws iam generate-credential-report
aws iam get-credential-report --output text | base64 -d > credential-report.csv

# Listar políticas del usuario y permisos efectivos
aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::123456789012:user/developer-juan --action-names s3:GetObject --resource-arns arn:aws:s3:::my-bucket/file.txt
```

## Ejercicios Prácticos

1. **Crear estructura de permisos por departamento:**
   - Crear grupos: `Developers`, `Operations`, `Analysts`
   - Asignar políticas apropiadas a cada grupo
   - Crear usuarios y asignarlos a grupos

2. **Implementar rol para Lambda:**
   ```bash
   # Crear rol que Lambda puede asumir
   aws iam create-role --role-name LambdaS3Role --assume-role-policy-document file://lambda-trust.json
   
   # Adjuntar políticas necesarias
   aws iam attach-role-policy --role-name LambdaS3Role --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
   ```

3. **Auditar permisos excesivos:**
   ```bash
   # Listar usuarios con políticas administrativas
   aws iam list-users --query 'Users[].UserName' | while read user; do
     echo "Usuario: $user"
     aws iam list-attached-user-policies --user-name $user
   done
   ```

## Recursos Adicionales

- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [IAM Policy Simulator](https://policysim.aws.amazon.com/)
- [AWS CLI IAM Reference](https://docs.aws.amazon.com/cli/latest/reference/iam/)

## Resumen

- **IAM** es fundamental para la seguridad en AWS
- **Usuarios** tienen credenciales permanentes; **roles** tienen credenciales temporales
- Usa **grupos** para gestionar permisos de múltiples usuarios
- Las **políticas** definen qué acciones están permitidas o denegadas
- Aplica el principio de **menor privilegio** siempre
- **Audita** y **rota** credenciales regularmente