# Plantillas, Stacks y Parámetros

## Plantillas (Templates)

Archivo declarativo que define infraestructura. Código versionable que especifica el estado deseado.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: mi-bucket-demo
```

## Stack

Instancia desplegada desde un template. La infraestructura real en ejecución.

```bash
aws cloudformation create-stack --stack-name demo-stack --template-body file://template.yaml
```

**Relación**: 1 template → N stacks (dev, prod, etc.)

## Parámetros

Valores dinámicos inyectados en tiempo de despliegue. Hacen el template reutilizable.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Parameters:
  BucketName:
    Type: String
    Description: Nombre del bucket

Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Ref BucketName
```

Inyección de valores al desplegar:

```bash
aws cloudformation create-stack \
  --stack-name demo-stack \
  --template-body file://template.yaml \
  --parameters ParameterKey=BucketName,ParameterValue=mi-bucket-prod
```

**Principios:**
- Evitar hardcodeo
- Template genérico, valores específicos por parámetros
- Un template, múltiples entornos