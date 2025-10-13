# Configuración de Jenkins

## 📋 Prerequisitos

- Jenkins >= 2.400
- Plugins requeridos:
  - Pipeline
  - Git
  - Credentials Binding
  - Terraform (opcional pero recomendado)

## 🔧 Instalación de Jenkins

### Docker (Recomendado para desarrollo)

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

### Instalación en Linux

```bash
# Debian/Ubuntu
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins

# Iniciar servicio
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

## 🚀 Configuración Inicial

### 1. Acceder a Jenkins

1. Abrir `http://localhost:8080`
2. Obtener contraseña inicial:
   ```bash
   sudo cat /var/jenkins_home/secrets/initialAdminPassword
   # o si instalaste con apt:
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. Instalar plugins sugeridos
4. Crear usuario admin

### 2. Instalar Plugins Adicionales

1. Ir a `Manage Jenkins` → `Manage Plugins`
2. Instalar:
   - Pipeline
   - Git Plugin
   - Credentials Binding Plugin
   - Terraform Plugin (opcional)
   - Blue Ocean (opcional, para mejor UI)

### 3. Instalar Herramientas

Instalar en el servidor de Jenkins:

```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.6.4/terraform_1.6.4_linux_amd64.zip
unzip terraform_1.6.4_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# doctl (para DOKS)
cd /tmp
wget https://github.com/digitalocean/doctl/releases/download/v1.98.1/doctl-1.98.1-linux-amd64.tar.gz
tar xf doctl-1.98.1-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin

# gcloud (para GKE)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

## 🔐 Configurar Credenciales

### 1. DigitalOcean Token (para DOKS)

1. Ir a `Manage Jenkins` → `Manage Credentials`
2. Seleccionar el dominio apropiado (Global)
3. Click en `Add Credentials`
4. Configurar:
   - **Kind**: Secret text
   - **Scope**: Global
   - **Secret**: Tu token de DigitalOcean
   - **ID**: `digitalocean-token`
   - **Description**: DigitalOcean API Token

### 2. Google Cloud Credentials (para GKE)

#### Opción A: Service Account Key File

1. `Add Credentials`
2. Configurar:
   - **Kind**: Secret file
   - **Scope**: Global
   - **File**: Upload del archivo JSON de service account
   - **ID**: `gcp-service-account`
   - **Description**: GCP Service Account

#### Opción B: Project ID

1. `Add Credentials`
2. Configurar:
   - **Kind**: Secret text
   - **Scope**: Global
   - **Secret**: Tu Project ID de GCP
   - **ID**: `gcp-project-id`
   - **Description**: GCP Project ID

### 3. GitHub/GitLab Credentials (opcional)

Para repositorios privados:

1. `Add Credentials`
2. Configurar:
   - **Kind**: Username with password (o SSH key)
   - **Username**: Tu usuario
   - **Password**: Token de acceso personal
   - **ID**: `github-credentials`

## 📝 Crear Pipeline

### Opción 1: Pipeline desde SCM (Recomendado)

1. Click en `New Item`
2. Nombre: `Kubernetes Infrastructure Pipeline`
3. Tipo: `Pipeline`
4. En la configuración:
   - **Pipeline Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: URL de tu repositorio
   - **Credentials**: (si es privado)
   - **Branch**: `*/master` o `*/main`
   - **Script Path**: `infra-ecommerce-microservice-backend-app/jenkins/Jenkinsfile`
5. Guardar

### Opción 2: Pipeline Script Directo

1. Click en `New Item`
2. Nombre: `Kubernetes Infrastructure Pipeline`
3. Tipo: `Pipeline`
4. En la sección Pipeline:
   - **Definition**: Pipeline script
   - Copiar el contenido del Jenkinsfile

## 🎯 Ejecutar Pipeline

### Primera Ejecución

1. Ir al job creado
2. Click en `Build with Parameters`
3. Seleccionar:
   - **PROVIDER**: `doks` o `gke`
   - **ENVIRONMENT**: `dev`
   - **ACTION**: `plan`
   - **AUTO_APPROVE**: `false`
4. Click en `Build`

### Desplegar Infraestructura

1. Después de verificar el plan
2. `Build with Parameters`
3. Seleccionar:
   - **PROVIDER**: `doks` o `gke`
   - **ENVIRONMENT**: `dev`
   - **ACTION**: `apply`
   - **AUTO_APPROVE**: `false` (para aprobación manual)
4. Click en `Build`
5. Aprobar cuando se solicite

## 📊 Monitoreo

### Ver Logs

- Click en el número de build
- Click en `Console Output`

### Ver Artefactos

- En la página del build, ver `Build Artifacts`
- Descargar `plan.txt` y `outputs.json`

### Blue Ocean (Opcional)

1. Instalar plugin Blue Ocean
2. Acceder desde el menú lateral
3. Vista más moderna y amigable

## 🔄 Webhooks (Opcional)

Para builds automáticos al hacer push:

### GitHub

1. Ir a Settings → Webhooks
2. Add webhook:
   - **Payload URL**: `http://your-jenkins/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Just the push event

### GitLab

1. Settings → Webhooks
2. Configurar:
   - **URL**: `http://your-jenkins/project/YOUR_JOB`
   - **Secret Token**: (configurar en Jenkins)
   - **Trigger**: Push events

## 🛡️ Seguridad

### 1. HTTPS

Configurar certificado SSL:

```bash
# Con Let's Encrypt y Nginx
sudo apt install nginx certbot python3-certbot-nginx
sudo certbot --nginx -d jenkins.yourdomain.com
```

### 2. Autenticación

- Habilitar autenticación basada en matriz
- Configurar LDAP/Active Directory
- Integrar con GitHub/GitLab OAuth

### 3. Autorización

1. `Manage Jenkins` → `Configure Global Security`
2. Authorization: `Matrix-based security`
3. Configurar permisos por usuario/grupo

### 4. Secrets

- Usar Credentials Plugin
- Nunca hacer commit de secrets
- Considerar HashiCorp Vault para producción

## 📋 Pipeline Multi-Branch (Avanzado)

Para gestionar múltiples branches:

1. `New Item` → `Multibranch Pipeline`
2. Configurar:
   - **Branch Sources**: Git/GitHub
   - **Scan Repository Triggers**: Periódicamente
3. Jenkins creará jobs automáticamente por branch

## 🐛 Troubleshooting

### Error: "terraform: command not found"

```bash
# Verificar PATH en Jenkins
# Manage Jenkins → Configure System → Global properties
# Environment variables
# NAME: PATH
# VALUE: /usr/local/bin:$PATH
```

### Error: "Permission denied"

```bash
# Agregar usuario jenkins a docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Error: "Unable to connect to cluster"

```bash
# Verificar que las herramientas estén en el PATH
# y que las credenciales estén configuradas correctamente
```

## 📚 Mejores Prácticas

1. **Usar Jenkinsfile en repositorio** (Pipeline as Code)
2. **Branches protegidas** para producción
3. **Aprobaciones manuales** para prod
4. **Notificaciones** (email, Slack)
5. **Backup de configuración** de Jenkins
6. **Múltiples agentes** para paralelización
7. **Escaneo de seguridad** en pipelines

## 📖 Referencias

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Best Practices](https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/)
- [Terraform in Jenkins](https://www.jenkins.io/doc/tutorials/#terraform)
