# Introducción a CloudFormation y AWS CLI

## Infraestructura como Código (IaC)

Gestión de infraestructura mediante archivos de configuración versionables en lugar de procesos manuales. Beneficios: reproducibilidad, trazabilidad, revisión de cambios, colaboración.

## CloudFormation

Herramienta declarativa de IaC que define recursos de nube en archivos (JSON/YAML). Declaras el estado deseado, el motor gestiona el estado real. Principios: idempotencia, atomicidad, rollback automático.

**Conceptos clave:**
- **Idempotencia**: ejecutar N veces produce el mismo resultado que ejecutar 1 vez.
- **Atomicidad**: todo se crea correctamente o nada se crea (transacción completa).
- **Rollback**: reversión automática al estado anterior si el despliegue falla.

## AWS CLI

Interfaz de línea de comandos para interactuar con APIs de AWS. Convierte operaciones manuales en scripts reproducibles y auditables. Base de pipelines CI/CD y automatización operativa.

---

## Práctica: crear una instancia EC2 con CloudFormation

En esta práctica introductoria vas a desplegar una instancia EC2 usando una plantilla de CloudFormation en formato YAML.

### Plantilla base (`ec2.yml`)

```yaml
Resources:
  NewEC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: "ami-0c101f26f147fa7fd"
      InstanceType: "t2.micro"
```

### Instrucciones resumidas

1. Crea el archivo `ec2.yml` con la plantilla anterior.
2. Entra a CloudFormation en la consola de AWS (región `us-east-1`):
   https://us-east-1.console.aws.amazon.com/cloudformation
3. Selecciona **Create stack** y luego **Upload a template file**.
4. Sube `ec2.yml`, haz clic en **Next** y asigna un nombre al stack.
5. Avanza con las opciones por defecto y despliega el stack.
6. Verifica que el estado final sea `CREATE_COMPLETE`.
7. Ve a EC2 y confirma que la instancia fue creada con el AMI y tipo correctos.

### Nota importante

Si el despliegue falla, revisa que estés en la región `us-east-1`.

### Cierre de la práctica

Para evitar costos, elimina el stack al terminar (esto borra también la instancia EC2).

Documentación oficial:
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html