# 🔍 Verificar Usuario de Jenkins

## Paso 1: Identificar el usuario de Jenkins

Conecta al servidor de Jenkins y ejecuta:

```bash
# Ver qué usuario ejecuta Jenkins
ps aux | grep jenkins | grep -v grep

# O verifica el proceso
ps -ef | grep jenkins | head -1
```

Probablemente verás algo como:
- `jenkins` (más común)
- `tomcat`
- `root` (no recomendado pero posible)

## Paso 2: Autenticar con ese usuario

Una vez que sepas el usuario, autentica con ese usuario:

### Si el usuario es 'jenkins':

```bash
# Opción A: Cambiar a usuario jenkins
sudo su - jenkins

# Luego autenticar
az login --use-device-code

# Verificar
az account show
```

### Si Jenkins corre como root:

```bash
# Ya lo hiciste, pero verifica que esté activo
az account show
```

## Paso 3: Verificar desde el pipeline

Agrega temporalmente esto al Jenkinsfile para ver quién ejecuta:

```groovy
sh '''
    echo "Usuario actual: $(whoami)"
    echo "Home directory: $HOME"
    az account show || echo "No autenticado"
'''
```

## Solución Rápida

**Ejecuta esto en el servidor de Jenkins:**

```bash
# Como root, ejecuta:
sudo su - jenkins -c "az login --use-device-code"
```

Esto autenticará Azure CLI específicamente para el usuario jenkins.

## Verificación

Después de autenticar, crea un Job simple en Jenkins:

```groovy
pipeline {
    agent any
    stages {
        stage('Test Azure') {
            steps {
                sh '''
                    whoami
                    az account show
                '''
            }
        }
    }
}
```

Si funciona, entonces está listo para usar en tu pipeline principal.
