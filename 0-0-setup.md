# Install AWS CLI in Windows Using Linux WSL

# Configuración de WSL + AWS CLI para Windows

## Requisitos previos
- Windows 10 (versión 2004+) o Windows 11
- VS Code instalado

---

## Paso 1: Instalar WSL (una sola vez)

Abre **PowerShell como Administrador** y ejecuta:

```powershell
wsl --install
```

Reinicia tu computadora cuando termine.

Al reiniciar, se abrirá Ubuntu. Crea un usuario y contraseña (recuérdalos).

---

## Paso 2: Instalar extensión WSL en VS Code

1. Abre VS Code
2. Ve a Extensions (Ctrl+Shift+X)
3. Busca e instala: **"WSL"** (de Microsoft)

---

## Paso 3: Abrir terminal WSL en VS Code

**Opción A - Abrir proyecto en WSL:**
1. Presiona `Ctrl+Shift+P`
2. Escribe: `WSL: Open Folder in WSL`
3. Navega a tu carpeta del proyecto

**Opción B - Solo terminal WSL:**
1. Abre terminal en VS Code (`Ctrl+``)
2. Click en el dropdown "+" → "Ubuntu (WSL)"

---

## Paso 4: Instalar AWS CLI en WSL

En la terminal WSL (Ubuntu), ejecuta estos comandos uno por uno:

```bash
# Actualizar paquetes
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y unzip curl

# Descargar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Instalar
unzip awscliv2.zip
sudo ./aws/install

# Limpiar archivos temporales
rm -rf aws awscliv2.zip

# Verificar instalación
aws --version
```

Deberías ver algo como: `aws-cli/2.x.x Python/3.x.x Linux/...`

---

## Paso 5: Configurar credenciales AWS (con perfiles)

Verificar AWS CLI:
```bash
aws --version
aws configure list-profiles  # Listar perfiles disponibles
```

### Opción 1: Usando `aws configure` (recomendado)

Obtén las access keys desde IAM Console: **User → Security credentials → Access keys → Create/Download CSV**

```bash
aws configure --profile <my profile>
# Te preguntará: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

### Opción 2: Configuración manual (editar archivos)

Crear/editar `~/.aws/config`:
```ini
[profile <my profile>]
region = us-east-1
output = json
```

Crear/editar `~/.aws/credentials`:
```ini
[<my profile>]
aws_access_key_id = TU_ACCESS_KEY_AQUI
aws_secret_access_key = TU_SECRET_KEY_AQUI
```

### Verificar que las credenciales funcionan

```bash
export AWS_PROFILE=<my profile>
aws sts get-caller-identity --profile "$AWS_PROFILE"
# Esperado: Retorna UserId, Account, Arn
```

> **Solución a `InvalidClientTokenId`:**  
> - Access keys inválidas/expiradas/eliminadas → Rotar keys en IAM Console  
> - Nunca compartas `~/.aws/credentials` – contiene keys sensibles

---

## Nota sobre rutas en WSL

En WSL, los discos de Windows están montados en `/mnt/`:
- `C:\Users\Juan\Documents` → `/mnt/c/Users/Juan/Documents`
- `D:\Proyectos` → `/mnt/d/Proyectos`

---

## Solución de problemas comunes

**AWS CLI no encontrado después de instalar**
```bash
source ~/.bashrc
# o cierra y abre una nueva terminal
```

**Ver si las credenciales funcionan**
```bash
aws sts get-caller-identity
```

---