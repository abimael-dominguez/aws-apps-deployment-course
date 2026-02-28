# Diseño de Red: VPC, Subredes, Grupos de Seguridad y NAT

## Introducción

Amazon VPC (Virtual Private Cloud) permite crear una red virtual aislada en AWS donde puedes lanzar recursos de AWS en una red que tú defines. Tienes control completo sobre tu entorno de red virtual, incluyendo la selección de rangos de direcciones IP, creación de subredes y configuración de tablas de ruteo y gateways.

## Conceptos Fundamentales

### 1. VPC (Virtual Private Cloud)

Red virtual privada aislada lógicamente en AWS:
- Rango de direcciones IP privadas (CIDR block)
- Segmentación mediante subredes
- Control total sobre configuración de red
- Aislamiento de otros clientes de AWS

**Ejemplo de CIDR:** `10.0.0.0/16` proporciona 65,536 direcciones IP

### 2. Subredes (Subnets)

Segmentos de una VPC ubicados en una zona de disponibilidad específica:

**Subnet Pública:**
- Tiene ruta a Internet Gateway
- Recursos con IP pública accesibles desde Internet
- Ejemplo: Servidores web, balanceadores de carga

**Subnet Privada:**
- Sin ruta directa a Internet
- Recursos accesibles solo desde dentro de la VPC
- Ejemplo: Bases de datos, servidores de aplicación

### 3. Internet Gateway (IGW)

Permite comunicación entre recursos en VPC e Internet:
- Proporciona conectividad de salida y entrada
- Altamente disponible y escalable
- Una VPC puede tener solo un IGW

### 4. NAT Gateway

Permite que recursos en subredes privadas accedan a Internet:
- Solo tráfico de salida (no permite conexiones entrantes)
- Gestionado por AWS (alta disponibilidad)
- Alternativa: NAT Instance (instancia EC2 que actúa como NAT)

### 5. Route Tables (Tablas de Ruteo)

Definen cómo se enruta el tráfico de red:
- Cada subnet está asociada a una tabla de ruteo
- Contiene reglas que determinan hacia dónde se dirige el tráfico
- Ruta local predeterminada para comunicación intra-VPC

### 6. Security Groups (Grupos de Seguridad)

Firewall a nivel de instancia:
- **Stateful**: Si permites entrada, la salida está automáticamente permitida
- Reglas solo de **Allow** (no hay Deny)
- Se aplica a interfaces de red (ENI)
- Puede hacer referencia a otros security groups

### 7. Network ACLs (Access Control Lists)

Firewall a nivel de subnet:
- **Stateless**: Debes definir reglas de entrada y salida explícitamente
- Soporta reglas de **Allow** y **Deny**
- Se evalúan en orden numérico
- Capa adicional de seguridad

## Comandos AWS CLI - VPC

### Crear y gestionar VPC

```bash
# Crear VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=MyAppVPC}]'

# Listar VPCs
aws ec2 describe-vpcs

# Listar VPCs con formato tabla
aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,State,Tags[?Key=='Name'].Value|[0]]" --output table

# Obtener VPC por ID
aws ec2 describe-vpcs --vpc-ids vpc-0123456789abcdef0

# Habilitar DNS hostnames en VPC
aws ec2 modify-vpc-attribute --vpc-id vpc-0123456789abcdef0 --enable-dns-hostnames

# Eliminar VPC (primero eliminar recursos dependientes)
aws ec2 delete-vpc --vpc-id vpc-0123456789abcdef0
```

### Obtener VPC predeterminada

```bash
# Ver VPC predeterminada
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true"

# Obtener ID de VPC predeterminada
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
```

## Comandos AWS CLI - Subnets

### Crear y gestionar subnets

```bash
# Crear subnet pública
aws ec2 create-subnet \
  --vpc-id vpc-0123456789abcdef0 \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet-1a}]'

# Crear subnet privada
aws ec2 create-subnet \
  --vpc-id vpc-0123456789abcdef0 \
  --cidr-block 10.0.10.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-Subnet-1a}]'

# Listar subnets de una VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0123456789abcdef0"

# Listar subnets con formato legible
aws ec2 describe-subnets --query "Subnets[].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key=='Name'].Value|[0]]" --output table

# Habilitar asignación automática de IP pública
aws ec2 modify-subnet-attribute --subnet-id subnet-0123456789abcdef0 --map-public-ip-on-launch

# Eliminar subnet
aws ec2 delete-subnet --subnet-id subnet-0123456789abcdef0
```

## Comandos AWS CLI - Internet Gateway

```bash
# Crear Internet Gateway
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=MyIGW}]'

# Listar Internet Gateways
aws ec2 describe-internet-gateways

# Adjuntar IGW a VPC
aws ec2 attach-internet-gateway --internet-gateway-id igw-0123456789abcdef0 --vpc-id vpc-0123456789abcdef0

# Desadjuntar IGW de VPC
aws ec2 detach-internet-gateway --internet-gateway-id igw-0123456789abcdef0 --vpc-id vpc-0123456789abcdef0

# Eliminar Internet Gateway
aws ec2 delete-internet-gateway --internet-gateway-id igw-0123456789abcdef0
```

## Comandos AWS CLI - NAT Gateway

```bash
# Crear NAT Gateway (requiere Elastic IP)
# Primero, asignar una Elastic IP
ALLOCATION_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

# Crear NAT Gateway en subnet pública
aws ec2 create-nat-gateway \
  --subnet-id subnet-0123456789abcdef0 \
  --allocation-id $ALLOCATION_ID \
  --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=MyNATGateway}]'

# Listar NAT Gateways
aws ec2 describe-nat-gateways

# Ver estado de NAT Gateway
aws ec2 describe-nat-gateways --nat-gateway-ids nat-0123456789abcdef0 --query "NatGateways[0].State" --output text

# Eliminar NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id nat-0123456789abcdef0

# Liberar Elastic IP (después de eliminar NAT Gateway)
aws ec2 release-address --allocation-id $ALLOCATION_ID
```

## Comandos AWS CLI - Route Tables

```bash
# Crear tabla de ruteo
aws ec2 create-route-table \
  --vpc-id vpc-0123456789abcdef0 \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PublicRouteTable}]'

# Listar tablas de ruteo
aws ec2 describe-route-tables

# Listar route tables de una VPC específica
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-0123456789abcdef0"

# Agregar ruta a Internet Gateway (subnet pública)
aws ec2 create-route \
  --route-table-id rtb-0123456789abcdef0 \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-0123456789abcdef0

# Agregar ruta a NAT Gateway (subnet privada)
aws ec2 create-route \
  --route-table-id rtb-9876543210fedcba0 \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id nat-0123456789abcdef0

# Asociar tabla de ruteo a subnet
aws ec2 associate-route-table \
  --route-table-id rtb-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0

# Eliminar ruta
aws ec2 delete-route --route-table-id rtb-0123456789abcdef0 --destination-cidr-block 0.0.0.0/0

# Eliminar tabla de ruteo
aws ec2 delete-route-table --route-table-id rtb-0123456789abcdef0
```

## Comandos AWS CLI - Security Groups

```bash
# Crear security group
aws ec2 create-security-group \
  --group-name web-server-sg \
  --description "Security group for web servers" \
  --vpc-id vpc-0123456789abcdef0

# Listar security groups
aws ec2 describe-security-groups

# Listar security groups de una VPC
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-0123456789abcdef0"

# Agregar regla de entrada (permitir HTTP desde cualquier lugar)
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Agregar regla de entrada (permitir SSH desde IP específica)
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp \
  --port 22 \
  --cidr 203.0.113.0/24

# Agregar regla que referencia otro security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp \
  --port 3306 \
  --source-group sg-9876543210fedcba0

# Agregar múltiples reglas con un solo comando
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --ip-permissions \
    IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges='[{CidrIp=0.0.0.0/0}]' \
    IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges='[{CidrIp=0.0.0.0/0}]'

# Remover regla de entrada
aws ec2 revoke-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Ver reglas de un security group
aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0

# Eliminar security group
aws ec2 delete-security-group --group-id sg-0123456789abcdef0
```

## Comandos AWS CLI - Network ACLs

```bash
# Crear Network ACL
aws ec2 create-network-acl \
  --vpc-id vpc-0123456789abcdef0 \
  --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=PublicNACL}]'

# Listar Network ACLs
aws ec2 describe-network-acls

# Agregar regla de entrada (permitir HTTP)
aws ec2 create-network-acl-entry \
  --network-acl-id acl-0123456789abcdef0 \
  --ingress \
  --rule-number 100 \
  --protocol tcp \
  --port-range From=80,To=80 \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

# Agregar regla de salida
aws ec2 create-network-acl-entry \
  --network-acl-id acl-0123456789abcdef0 \
  --egress \
  --rule-number 100 \
  --protocol tcp \
  --port-range From=80,To=80 \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

# Asociar NACL a subnet
aws ec2 replace-network-acl-association \
  --association-id aclassoc-0123456789abcdef0 \
  --network-acl-id acl-0123456789abcdef0

# Eliminar regla de NACL
aws ec2 delete-network-acl-entry \
  --network-acl-id acl-0123456789abcdef0 \
  --ingress \
  --rule-number 100

# Eliminar Network ACL
aws ec2 delete-network-acl --network-acl-id acl-0123456789abcdef0
```

## Ejemplo Práctico: Crear VPC Completa con Alta Disponibilidad

```bash
#!/bin/bash
# Script para crear VPC con arquitectura Multi-AZ

VPC_NAME="production-vpc"
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"

echo "=== Creando VPC ==="
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]" \
  --query 'Vpc.VpcId' --output text)
echo "VPC creada: $VPC_ID"

# Habilitar DNS
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

echo "\n=== Creando Internet Gateway ==="
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${VPC_NAME}-igw}]" \
  --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "Internet Gateway creado: $IGW_ID"

echo "\n=== Creando Subnets Públicas ==="
PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ${REGION}a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${VPC_NAME}-public-1a}]" \
  --query 'Subnet.SubnetId' --output text)
echo "Subnet pública 1a: $PUBLIC_SUBNET_1"

PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone ${REGION}b \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${VPC_NAME}-public-1b}]" \
  --query 'Subnet.SubnetId' --output text)
echo "Subnet pública 1b: $PUBLIC_SUBNET_2"

# Habilitar IPs públicas automáticas
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_1 --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_2 --map-public-ip-on-launch

echo "\n=== Creando Subnets Privadas ==="
PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.10.0/24 \
  --availability-zone ${REGION}a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${VPC_NAME}-private-1a}]" \
  --query 'Subnet.SubnetId' --output text)
echo "Subnet privada 1a: $PRIVATE_SUBNET_1"

PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.11.0/24 \
  --availability-zone ${REGION}b \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${VPC_NAME}-private-1b}]" \
  --query 'Subnet.SubnetId' --output text)
echo "Subnet privada 1b: $PRIVATE_SUBNET_2"

echo "\n=== Creando NAT Gateways ==="
# Crear Elastic IPs
EIP_1=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
EIP_2=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

# Crear NAT Gateways en cada subnet pública
NAT_GW_1=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_1 \
  --allocation-id $EIP_1 \
  --tag-specifications "ResourceType=nat-gateway,Tags=[{Key=Name,Value=${VPC_NAME}-nat-1a}]" \
  --query 'NatGateway.NatGatewayId' --output text)
echo "NAT Gateway 1a: $NAT_GW_1"

NAT_GW_2=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_2 \
  --allocation-id $EIP_2 \
  --tag-specifications "ResourceType=nat-gateway,Tags=[{Key=Name,Value=${VPC_NAME}-nat-1b}]" \
  --query 'NatGateway.NatGatewayId' --output text)
echo "NAT Gateway 1b: $NAT_GW_2"

echo "Esperando que NAT Gateways estén disponibles..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_1 $NAT_GW_2

echo "\n=== Creando Route Tables ==="
# Route table para subnets públicas
PUBLIC_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${VPC_NAME}-public-rt}]" \
  --query 'RouteTable.RouteTableId' --output text)
echo "Route table pública: $PUBLIC_RT"

# Agregar ruta a Internet Gateway
aws ec2 create-route --route-table-id $PUBLIC_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# Asociar subnets públicas
aws ec2 associate-route-table --route-table-id $PUBLIC_RT --subnet-id $PUBLIC_SUBNET_1
aws ec2 associate-route-table --route-table-id $PUBLIC_RT --subnet-id $PUBLIC_SUBNET_2

# Route tables para subnets privadas
PRIVATE_RT_1=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${VPC_NAME}-private-rt-1a}]" \
  --query 'RouteTable.RouteTableId' --output text)
echo "Route table privada 1a: $PRIVATE_RT_1"

PRIVATE_RT_2=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${VPC_NAME}-private-rt-1b}]" \
  --query 'RouteTable.RouteTableId' --output text)
echo "Route table privada 1b: $PRIVATE_RT_2"

# Agregar rutas a NAT Gateways
aws ec2 create-route --route-table-id $PRIVATE_RT_1 --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_1
aws ec2 create-route --route-table-id $PRIVATE_RT_2 --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_2

# Asociar subnets privadas
aws ec2 associate-route-table --route-table-id $PRIVATE_RT_1 --subnet-id $PRIVATE_SUBNET_1
aws ec2 associate-route-table --route-table-id $PRIVATE_RT_2 --subnet-id $PRIVATE_SUBNET_2

echo "\n=== Creando Security Groups ==="
# Security group para web servers
WEB_SG=$(aws ec2 create-security-group \
  --group-name "${VPC_NAME}-web-sg" \
  --description "Security group for web servers" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
echo "Web Security Group: $WEB_SG"

# Agregar reglas para web
aws ec2 authorize-security-group-ingress --group-id $WEB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $WEB_SG --protocol tcp --port 443 --cidr 0.0.0.0/0

# Security group para base de datos
DB_SG=$(aws ec2 create-security-group \
  --group-name "${VPC_NAME}-db-sg" \
  --description "Security group for databases" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
echo "Database Security Group: $DB_SG"

# Permitir acceso desde web servers
aws ec2 authorize-security-group-ingress --group-id $DB_SG --protocol tcp --port 3306 --source-group $WEB_SG

echo "\n=== Resumen de Configuración ==="
echo "VPC ID: $VPC_ID"
echo "CIDR: $VPC_CIDR"
echo "Internet Gateway: $IGW_ID"
echo "Public Subnets: $PUBLIC_SUBNET_1, $PUBLIC_SUBNET_2"
echo "Private Subnets: $PRIVATE_SUBNET_1, $PRIVATE_SUBNET_2"
echo "NAT Gateways: $NAT_GW_1, $NAT_GW_2"
echo "Security Groups: Web=$WEB_SG, DB=$DB_SG"
echo "\n¡VPC configurada exitosamente!"
```

## Arquitectura de Referencia

```
┌─────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                    │
├──────────────────────┬──────────────────────────────────┤
│   AZ us-east-1a      │      AZ us-east-1b              │
├──────────────────────┼──────────────────────────────────┤
│ Public Subnet 1a     │   Public Subnet 1b              │
│ 10.0.1.0/24          │   10.0.2.0/24                   │
│ - NAT Gateway 1      │   - NAT Gateway 2               │
│ - Load Balancer      │   - Load Balancer               │
├──────────────────────┼──────────────────────────────────┤
│ Private Subnet 1a    │   Private Subnet 1b             │
│ 10.0.10.0/24         │   10.0.11.0/24                  │
│ - App Servers        │   - App Servers                 │
│ - Database (Primary) │   - Database (Standby)          │
└──────────────────────┴──────────────────────────────────┘
           ↑                         ↑
           │    Internet Gateway     │
           └─────────────────────────┘
                      ↑
                   Internet
```

## Mejores Prácticas

### 1. Diseño Multi-AZ
- Distribuye recursos en al menos 2 zonas de disponibilidad
- Coloca NAT Gateways en cada AZ para redundancia
- Usa balanceadores de carga multi-AZ

### 2. Separación de Capas
```
Public Tier    → Balanceadores de carga, Bastion hosts
Application Tier → Servidores de aplicación
Data Tier      → Bases de datos, caché
```

### 3. Security Groups vs NACLs
- **Security Groups**: Primera línea de defensa (preferido)
- **NACLs**: Capa adicional de seguridad, útil para bloquear IPs específicas

### 4. CIDR Planning
```bash
# Deja espacio para crecimiento
VPC:           10.0.0.0/16    (65,536 IPs)
Public Subnets: 10.0.0.0/20    (4,096 IPs)  
Private Subnets: 10.0.16.0/20   (4,096 IPs)
Future Use:    10.0.32.0/19    (Reservado)
```

### 5. Naming y Tagging
```bash
# Usa nombres descriptivos y consistentes
Name: production-vpc-public-subnet-1a
Environment: production
Tier: public
AZ: us-east-1a
```

### 6. Limitar Acceso SSH
```bash
# ❌ No permitir SSH desde cualquier lugar
aws ec2 authorize-security-group-ingress --group-id sg-xxx --protocol tcp --port 22 --cidr 0.0.0.0/0

# ✅ Usar bastion host o IP específica
aws ec2 authorize-security-group-ingress --group-id sg-xxx --protocol tcp --port 22 --cidr 203.0.113.0/32
```

## Troubleshooting Común

### Verificar conectividad de Internet desde subnet privada

```bash
# Verificar que subnet privada tiene ruta a NAT Gateway
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=subnet-xxx" \
  --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].NatGatewayId"

# Verificar estado de NAT Gateway
aws ec2 describe-nat-gateways --nat-gateway-ids nat-xxx --query "NatGateways[0].State"
```

### Diagnosticar problemas de seguridad

```bash
# Ver todas las reglas de entrada de un security group
aws ec2 describe-security-groups --group-ids sg-xxx --query "SecurityGroups[0].IpPermissions"

# Ver todas las reglas de salida
aws ec2 describe-security-groups --group-ids sg-xxx --query "SecurityGroups[0].IpPermissionsEgress"

# Listar instancias usando un security group
aws ec2 describe-instances --filters "Name=instance.group-id,Values=sg-xxx" --query "Reservations[].Instances[].[InstanceId,State.Name]"
```

## Ejercicios Prácticos

1. **Crear VPC de 3 capas:**
   - Subnet pública para load balancers
   - Subnet privada para aplicación
   - Subnet privada aislada para base de datos

2. **Implementar bastion host:**
   - Crear subnet pública pequeña solo para bastion
   - Configurar security group que permita SSH solo desde bastion a subnets privadas

3. **Configurar VPC Peering:**
   ```bash
   # Crear peering entre dos VPCs
   aws ec2 create-vpc-peering-connection --vpc-id vpc-1 --peer-vpc-id vpc-2
   ```

## Recursos Adicionales

- [VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [VPC Examples](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenarios.html)
- [AWS CLI VPC Reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/)

## Resumen

- **VPC** proporciona aislamiento de red en AWS
- **Subnets** públicas tienen acceso directo a Internet; privadas usan NAT
- **Security Groups** son stateful; **NACLs** son stateless
- Diseña arquitecturas **multi-AZ** para alta disponibilidad
- Usa **NAT Gateways** en lugar de NAT Instances (gestionados por AWS)
- Planifica tu **CIDR** cuidadosamente dejando espacio para crecimiento