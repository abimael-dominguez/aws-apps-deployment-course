# Arquitectura de AWS: Regiones, Zonas y Servicios Básicos

## Introducción

AWS (Amazon Web Services) es una plataforma de servicios en la nube que opera en una infraestructura global distribuida. Comprender su arquitectura es fundamental para diseñar aplicaciones escalables, resilientes y de alta disponibilidad.

## Conceptos Clave

### 1. Regiones (Regions)

Una región de AWS es una ubicación geográfica física que contiene múltiples centros de datos. Cada región:
- Es completamente independiente de otras regiones
- Tiene su propia infraestructura, servicios y precios
- Permite cumplir con requisitos de soberanía de datos
- Proporciona baja latencia para usuarios en esa geografía

**Ejemplos de regiones:**
- `us-east-1` (Norte de Virginia)
- `eu-west-1` (Irlanda)
- `ap-southeast-1` (Singapur)
- `sa-east-1` (São Paulo)

### 2. Zonas de Disponibilidad (Availability Zones - AZ)

Cada región contiene múltiples zonas de disponibilidad (típicamente 3 o más):
- Son centros de datos aislados físicamente dentro de una región
- Tienen energía, redes y conectividad redundantes
- Están conectadas entre sí con enlaces de alta velocidad y baja latencia
- Permiten diseñar aplicaciones tolerantes a fallos

**Ejemplo:** La región `us-east-1` tiene 6 AZs: `us-east-1a`, `us-east-1b`, `us-east-1c`, etc.

### 3. Edge Locations

Son puntos de presencia (PoP) utilizados por servicios como:
- **CloudFront** (CDN)
- **Route 53** (DNS)
- **AWS Global Accelerator**

Hay más de 400 edge locations en todo el mundo, proporcionando contenido con baja latencia a usuarios finales.

## Comandos AWS CLI

### Listar todas las regiones disponibles

```bash
# Listar todas las regiones
aws ec2 describe-regions

# Listar regiones con formato de tabla
aws ec2 describe-regions --output table

# Obtener solo los nombres de las regiones
aws ec2 describe-regions --query "Regions[].RegionName" --output text
```

### Obtener información de una región específica

```bash
# Detalles de una región específica
aws ec2 describe-regions --region-names us-east-1

# Con formato JSON legible
aws ec2 describe-regions --region-names us-east-1 --output json | jq
```

### Listar zonas de disponibilidad

```bash
# Listar todas las AZs de la región configurada por defecto
aws ec2 describe-availability-zones

# Listar AZs de una región específica
aws ec2 describe-availability-zones --region us-west-2

# Obtener solo nombres de las AZs
aws ec2 describe-availability-zones --query "AvailabilityZones[].ZoneName" --output text

# Ver el estado de las AZs (available, impaired, unavailable)
aws ec2 describe-availability-zones --query "AvailabilityZones[].[ZoneName,State]" --output table
```

### Listar servicios disponibles en una región

```bash
# Listar todos los servicios con cuotas en una región
aws service-quotas list-services --region us-east-1

# Buscar un servicio específico (ejemplo: Lambda)
aws service-quotas list-services --region us-east-1 \
  --query "Services[?contains(ServiceName, 'Lambda')]"

# Ver información de disponibilidad de servicios por región
aws ssm get-parameters-by-path \
  --path /aws/service/global-infrastructure/regions/us-east-1/services \
  --region us-east-1
```

### Configurar región predeterminada

```bash
# Ver configuración actual
aws configure get region

# Establecer región predeterminada
aws configure set region us-east-1

# Verificar configuración completa
aws configure list
```

## Servicios Básicos de AWS

### Cómputo
- **EC2** (Elastic Compute Cloud): Máquinas virtuales
- **Lambda**: Ejecución serverless de código
- **ECS/EKS**: Orquestación de contenedores
- **Elastic Beanstalk**: Plataforma como servicio (PaaS)

### Almacenamiento
- **S3** (Simple Storage Service): Almacenamiento de objetos
- **EBS** (Elastic Block Store): Volúmenes de disco para EC2
- **EFS** (Elastic File System): Sistema de archivos compartido
- **Glacier**: Almacenamiento de archivo de bajo costo

### Bases de Datos
- **RDS**: Bases de datos relacionales gestionadas
- **DynamoDB**: Base de datos NoSQL
- **ElastiCache**: Caché en memoria (Redis/Memcached)
- **Aurora**: Base de datos relacional de alto rendimiento

### Redes
- **VPC**: Red virtual privada
- **Route 53**: Servicio de DNS
- **CloudFront**: Red de distribución de contenido (CDN)
- **ELB**: Balanceadores de carga

## Ejemplo Práctico: Exploración de Arquitectura

```bash
#!/bin/bash
# Script para explorar la arquitectura de AWS

echo "=== Regiones Disponibles ==="
aws ec2 describe-regions --query "Regions[].[RegionName,Endpoint]" --output table

echo "\n=== Zonas de Disponibilidad en us-east-1 ==="
aws ec2 describe-availability-zones --region us-east-1 --query "AvailabilityZones[].[ZoneName,State,RegionName]" --output table

echo "\n=== Configuración Actual ==="
echo "Región: $(aws configure get region)"
echo "Output: $(aws configure get output)"

echo "\n=== Account ID ==="
aws sts get-caller-identity --query Account --output text
```

## Mejores Prácticas

1. **Multi-región para DR**: Diseña aplicaciones críticas en múltiples regiones para recuperación ante desastres

2. **Multi-AZ para alta disponibilidad**: Distribuye recursos en al menos 2 zonas de disponibilidad dentro de una región

3. **Proximidad geográfica**: Selecciona regiones cercanas a tus usuarios para reducir latencia

4. **Cumplimiento normativo**: Considera requisitos legales de residencia de datos al elegir regiones

5. **Costos**: Los precios varían entre regiones; evalúa el balance entre costo y rendimiento

6. **Disponibilidad de servicios**: No todos los servicios están disponibles en todas las regiones

## Consideraciones de Diseño

### Arquitectura Multi-AZ
```
Región: us-east-1
├── AZ us-east-1a
│   ├── Subnet pública
│   ├── Subnet privada
│   └── Instancias EC2
├── AZ us-east-1b
│   ├── Subnet pública
│   ├── Subnet privada
│   └── Instancias EC2
└── Load Balancer (distribuye tráfico entre AZs)
```

### Arquitectura Multi-Región
```
Región Primaria: us-east-1
├── Aplicación principal
├── Base de datos primaria
└── Replicación a región secundaria

Región Secundaria: eu-west-1
├── Aplicación en standby
├── Base de datos réplica
└── Route 53 (failover automático)
```

## Ejercicios Prácticos

1. **Exploración de regiones:**
   ```bash
   # Cuenta cuántas regiones hay disponibles
   aws ec2 describe-regions --query "length(Regions)"
   
   # Encuentra regiones en Asia
   aws ec2 describe-regions --query "Regions[?contains(RegionName, 'ap')].RegionName"
   ```

2. **Análisis de zonas:**
   ```bash
   # Cuenta las AZs en tu región actual
   aws ec2 describe-availability-zones --query "length(AvailabilityZones)"
   
   # Verifica el estado de todas las AZs
   aws ec2 describe-availability-zones --filters "Name=state,Values=available" --query "AvailabilityZones[].ZoneName"
   ```

## Recursos Adicionales

- [AWS Global Infrastructure](https://aws.amazon.com/about-aws/global-infrastructure/)
- [Regiones y Zonas de Disponibilidad](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)
- [AWS CLI Reference - EC2](https://docs.aws.amazon.com/cli/latest/reference/ec2/)

## Resumen

- AWS opera en **regiones** globales, cada una con múltiples **zonas de disponibilidad**
- Las AZs permiten diseñar aplicaciones de alta disponibilidad
- Los comandos `aws ec2 describe-regions` y `aws ec2 describe-availability-zones` son fundamentales para la exploración
- Selecciona regiones basándote en latencia, cumplimiento normativo y costos
- Distribuye recursos en múltiples AZs para resiliencia