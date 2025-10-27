pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }

  parameters {
    choice(name: 'ACTION', choices: ['status', 'create', 'rebuild', 'destroy'], description: 'Acción a ejecutar sobre la VM (status por defecto para evitar creación automática)')
    choice(name: 'VM_CONFIG', choices: ['standard', 'ecommerce_minikube'], description: 'Configuración predefinida de la VM')
    string(name: 'VM_NAME', defaultValue: 'ecommerce-integration-runner', description: 'Nombre del droplet en DigitalOcean')
    string(name: 'VM_REGION', defaultValue: 'nyc3', description: 'Región donde se creará el droplet')
    string(name: 'VM_SIZE', defaultValue: 's-1vcpu-2gb', description: 'Plan/tamaño de la VM (se sobrescribe automáticamente según VM_CONFIG)')
    string(name: 'VM_IMAGE', defaultValue: 'ubuntu-22-04-x64', description: 'Imagen base a utilizar')
    booleanParam(name: 'ARCHIVE_METADATA', defaultValue: true, description: 'Publicar droplet.properties y jenkins-env.properties como artefactos')
    booleanParam(name: 'CONFIGURE_GCP_ACCESS', defaultValue: true, description: 'Copiar credenciales de GCP y dejar listo gcloud en la VM (solo create/rebuild)')
  }

  environment {
    INFRA_DIR = "infra/digitalocean-vm"
    PROPERTIES_FILE = "droplet.properties"
    JENKINS_ENV_FILE = "jenkins-env.properties"
  }

  stages {
    stage('Configure VM Settings') {
      steps {
        script {
          // Configuraciones predefinidas según el tipo de VM
          def configs = [
            'standard': [
              size: 's-1vcpu-2gb',
              cloudInitTemplate: 'cloud-init.yaml',
              description: 'VM estándar para pruebas de integración'
            ],
            'ecommerce_minikube': [
              size: 's-2vcpu-4gb',  // 4GB RAM, 2 CPUs como especificaste
              cloudInitTemplate: 'cloud-init-minikube.yaml',
              description: 'VM optimizada para Minikube con recursos adicionales'
            ]
          ]
          
          def selectedConfig = configs[params.VM_CONFIG]
          if (!selectedConfig) {
            error "❌ Configuración de VM no válida: ${params.VM_CONFIG}"
          }
          
          // Usar el tamaño de la configuración seleccionada
          env.FINAL_SIZE = selectedConfig.size
          env.CLOUD_INIT_TEMPLATE = selectedConfig.cloudInitTemplate
          
          echo "🔧 Configuración seleccionada: ${params.VM_CONFIG}"
          echo "📊 Tamaño de VM: ${env.FINAL_SIZE}"
          echo "📄 Template cloud-init: ${env.CLOUD_INIT_TEMPLATE}"
          echo "📝 Descripción: ${selectedConfig.description}"
          
          // Mostrar información importante sobre la acción
          if (params.ACTION == 'create') {
            echo "⚠️  ATENCIÓN: Se creará una nueva VM con las siguientes características:"
            echo "   • Nombre: ${params.VM_NAME}"
            echo "   • Región: ${params.VM_REGION}"
            echo "   • Tamaño: ${env.FINAL_SIZE}"
            echo "   • Imagen: ${params.VM_IMAGE}"
            echo "   • Costo estimado: ${env.FINAL_SIZE == 's-2vcpu-4gb' ? '~$24/mes' : '~$12/mes'}"
          } else if (params.ACTION == 'destroy') {
            echo "⚠️  ATENCIÓN: Se eliminará la VM '${params.VM_NAME}' permanentemente"
          } else if (params.ACTION == 'rebuild') {
            echo "⚠️  ATENCIÓN: Se eliminará y recreará la VM '${params.VM_NAME}'"
          } else {
            echo "ℹ️  Solo se consultará el estado de la VM '${params.VM_NAME}'"
          }
        }
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
        script {
          echo "📦 Workspace: ${env.WORKSPACE}"
          echo "➤ Acción: ${params.ACTION}"
          echo "➤ Configuración: ${params.VM_CONFIG}"
          echo "➤ Droplet: ${params.VM_NAME} (${params.VM_REGION}, ${env.FINAL_SIZE}, ${params.VM_IMAGE})"
        }
      }
    }

    stage('Prepare Scripts') {
      steps {
        dir("${env.INFRA_DIR}") {
          sh '''
            set -e
            chmod +x *.sh
            echo "✅ Scripts de DigitalOcean listos."
          '''
        }
      }
    }

    stage('Execute Action') {
      steps {
        withCredentials([
          string(credentialsId: 'digitalocean-token', variable: 'DO_TOKEN'),
          string(credentialsId: 'integration-vm-password', variable: 'VM_PASSWORD')
        ]) {
          script {
            def action = params.ACTION
            
            def commonEnv = [
              "NAME=${params.VM_NAME}",
              "REGION=${params.VM_REGION}",
              "SIZE=${env.FINAL_SIZE}",
              "IMAGE=${params.VM_IMAGE}",
              "CLOUD_INIT_TEMPLATE=${env.CLOUD_INIT_TEMPLATE}"
            ]

            if (action == 'create') {
              withEnv(commonEnv + ["VM_PASSWORD=${VM_PASSWORD}"]) {
                dir(env.INFRA_DIR) {
                  sh '''
                    set -e
                    ./create-do-droplet.sh
                  '''
                }
              }
            } else if (action == 'rebuild') {
              withEnv(commonEnv + ["ALLOW_MISSING=1"]) {
                dir(env.INFRA_DIR) {
                  sh '''
                    set -e
                    echo "🔁 Eliminando droplet existente (si aplica)..."
                    ./delete-do-droplet.sh || true
                  '''
                }
              }
              sleep(time: 10, unit: 'SECONDS')
              withEnv(commonEnv + ["VM_PASSWORD=${VM_PASSWORD}"]) {
                dir(env.INFRA_DIR) {
                  sh '''
                    set -e
                    echo "🚀 Creando droplet desde cero..."
                    ./create-do-droplet.sh
                  '''
                }
              }
            } else if (action == 'destroy') {
              withEnv(commonEnv + ["ALLOW_MISSING=1"]) {
                dir(env.INFRA_DIR) {
                  sh '''
                    set -e
                    ./delete-do-droplet.sh
                  '''
                }
              }
            } else {
              echo "ℹ️ Acción de solo estado - no se realizan cambios en DigitalOcean."
            }
          }
        }
      }
    }

    stage('Fetch Metadata') {
      steps {
        withCredentials([string(credentialsId: 'digitalocean-token', variable: 'DO_TOKEN')]) {
          script {
            def ip = ""
            if (params.ACTION != 'destroy') {
              ip = sh(
                script: """
                  set -e
                  curl -sS -H "Authorization: Bearer ${DO_TOKEN}" "https://api.digitalocean.com/v2/droplets?per_page=200" \\
                    | jq -r --arg NAME "${params.VM_NAME}" '.droplets[] | select(.name==\$NAME) | .networks.v4[] | select(.type=="public") | .ip_address' \\
                    | head -n1
                """,
                returnStdout: true
              ).trim()
            }

            if (ip) {
              echo "🌐 IP pública actual: ${ip}"
              env.DROPLET_IP = ip
              env.VM_IP_ADDRESS = ip
            } else {
              echo "ℹ️ No se encontró IP pública (droplet inexistente o recién destruido)."
              env.DROPLET_IP = ""
              env.VM_IP_ADDRESS = ""
            }

            writeFile file: env.PROPERTIES_FILE, text: """VM_NAME=${params.VM_NAME}
DROPLET_IP=${env.DROPLET_IP ?: ''}
ACTION=${params.ACTION}
VM_CONFIG=${params.VM_CONFIG}
REGION=${params.VM_REGION}
SIZE=${env.FINAL_SIZE}
IMAGE=${params.VM_IMAGE}
CLOUD_INIT_TEMPLATE=${env.CLOUD_INIT_TEMPLATE}
"""

            def triggeredBy = env.BUILD_USER_ID ?: env.BUILD_USER ?: env.BUILD_TAG ?: 'jenkins'

            writeFile file: env.JENKINS_ENV_FILE, text: """VM_NAME=${params.VM_NAME}
DROPLET_IP=${env.DROPLET_IP ?: ''}
VM_IP_ADDRESS=${env.VM_IP_ADDRESS ?: ''}
ACTION=${params.ACTION}
VM_CONFIG=${params.VM_CONFIG}
BUILD_NUMBER=${env.BUILD_NUMBER}
JOB_NAME=${env.JOB_NAME}
TRIGGERED_BY=${triggeredBy}
TIMESTAMP=${new Date().format('yyyy-MM-dd HH:mm:ss')}
"""

            if (params.ARCHIVE_METADATA) {
              archiveArtifacts artifacts: "${env.PROPERTIES_FILE},${env.JENKINS_ENV_FILE}", fingerprint: true
            }
          }
        }
      }
    }

    stage('Configure Minikube') {
      when {
        expression {
          params.VM_CONFIG == 'ecommerce_minikube' &&
            env.DROPLET_IP &&
            (params.ACTION == 'create' || params.ACTION == 'rebuild')
        }
      }
      steps {
        withCredentials([
          string(credentialsId: 'integration-vm-password', variable: 'VM_PASSWORD')
        ]) {
          script {
            def targetIp = env.DROPLET_IP
            if (!targetIp) {
              error "❌ No hay IP disponible para configurar Minikube en la VM."
            }

            echo "🚀 Configurando Minikube en ${targetIp}..."

            sh """
set -e
export SSHPASS="\$VM_PASSWORD"

echo "⏳ Esperando a que la VM acepte conexiones SSH..."
READY=0
for i in \$(seq 1 30); do
  if sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@${targetIp} "echo VM ready" >/dev/null 2>&1; then
    READY=1
    break
  fi
  echo "   reintentando (\$i/30)..."
  sleep 10
done
if [ "\$READY" -ne 1 ]; then
  echo "❌ No fue posible establecer conexión SSH con ${targetIp}"
  exit 1
fi

echo "🔧 Configurando Minikube..."
sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@${targetIp} << 'MINIKUBE_CONFIG'
set -euo pipefail

echo "🔍 Verificando estado de Minikube..."
if minikube status >/dev/null 2>&1; then
  echo "✅ Minikube ya está ejecutándose"
else
  echo "🚀 Iniciando Minikube..."
  minikube start --driver=docker --memory=3072 --cpus=2 --disk-size=20g
fi

echo "📊 Estado de Minikube:"
minikube status

echo "🔧 Configurando kubectl..."
minikube kubectl -- get nodes || true

echo "🌐 Servicios disponibles:"
minikube service list || true

echo "📋 Información del cluster:"
minikube kubectl -- get all || true

echo "✅ Minikube configurado exitosamente"
MINIKUBE_CONFIG

echo "🎉 Configuración de Minikube completada"
"""
          }
        }
      }
    }

    stage('Configure GCP Access') {
      when {
        expression {
          params.CONFIGURE_GCP_ACCESS &&
            env.DROPLET_IP &&
            (params.ACTION == 'create' || params.ACTION == 'rebuild')
        }
      }
      steps {
        withCredentials([
          string(credentialsId: 'integration-vm-password', variable: 'VM_PASSWORD'),
          string(credentialsId: 'gcp-project-id', variable: 'GCP_PROJECT_ID'),
          file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
        ]) {
          script {
            def targetIp = env.DROPLET_IP
            if (!targetIp) {
              error "❌ No hay IP disponible para configurar gcloud en la VM."
            }

            echo "🔐 Configurando acceso a GCP en ${targetIp}..."

            sh """
set -e
export SSHPASS="\$VM_PASSWORD"

echo "⏳ Esperando a que la VM acepte conexiones SSH..."
READY=0
for i in \$(seq 1 30); do
  if sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@${targetIp} "echo VM ready" >/dev/null 2>&1; then
    READY=1
    break
  fi
  echo "   reintentando (\$i/30)..."
  sleep 10
done
if [ "\$READY" -ne 1 ]; then
  echo "❌ No fue posible establecer conexión SSH con ${targetIp}"
  exit 1
fi

sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@${targetIp} "mkdir -p ~/.config/gcloud && chmod 700 ~/.config/gcloud"

TMP_REMOTE_CRED="/home/jenkins/.config/gcloud/service-account.json"
sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "\$GOOGLE_APPLICATION_CREDENTIALS" jenkins@${targetIp}:"\$TMP_REMOTE_CRED"
sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@${targetIp} "chmod 600 \$TMP_REMOTE_CRED"

sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@${targetIp} "
  set -e
  export CLOUDSDK_CORE_DISABLE_PROMPTS=1
  gcloud auth activate-service-account --key-file=\$TMP_REMOTE_CRED
  gcloud config set project '$GCP_PROJECT_ID'
  gcloud auth configure-docker us-docker.pkg.dev --quiet || true
  gcloud auth configure-docker gcr.io --quiet || true
  echo '✅ gcloud configurado para el proyecto $GCP_PROJECT_ID'
"
"""
          }
        }
      }
    }

    stage('Summary') {
      steps {
        script {
          def ip = env.DROPLET_IP ?: 'N/A'
          echo """
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Jenkins_Create_VM Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Acción ejecutada : ${params.ACTION.toUpperCase()}
• Configuración    : ${params.VM_CONFIG}
• Droplet          : ${params.VM_NAME}
• Región / Size    : ${params.VM_REGION} / ${env.FINAL_SIZE}
• Imagen           : ${params.VM_IMAGE}
• IP pública       : ${ip}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline Jenkins_Create_VM completado."
    }
    failure {
      echo "❌ Jenkins_Create_VM falló. Revisa los logs para más detalles."
    }
    always {
      cleanWs(patterns: [[pattern: '**/*.tfstate', type: 'EXCLUDE']])
    }
  }
}
