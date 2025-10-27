pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }

  parameters {
    choice(name: 'ACTION', choices: ['status', 'create', 'rebuild', 'destroy'], description: 'Acción a ejecutar sobre la VM (status por defecto para evitar creación automática)')
    choice(name: 'VM_CONFIG', choices: ['standard', 'ecommerce_minikube'], description: 'Configuración predefinida de la VM (ecommerce_minikube usa Terraform + Ansible)')
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
              name: 'ecommerce-integration-runner',
              size: 's-1vcpu-2gb',
              region: 'nyc3',
              image: 'ubuntu-22-04-x64',
              cloudInitTemplate: 'cloud-init.yaml',
              description: 'VM estándar para pruebas de integración',
              cost: '~$12/mes'
            ],
            'ecommerce_minikube': [
              name: 'ecommerce-minikube-dev',
              size: 's-2vcpu-4gb',  // 4GB RAM, 2 CPUs como especificaste
              region: 'nyc3',
              image: 'ubuntu-22-04-x64',
              cloudInitTemplate: 'cloud-init-minikube.yaml',
              description: 'VM optimizada para Minikube con Terraform + Ansible (sin conflictos de cloud-init)',
              cost: '~$24/mes'
            ]
          ]
          
          def selectedConfig = configs[params.VM_CONFIG]
          if (!selectedConfig) {
            error "❌ Configuración de VM no válida: ${params.VM_CONFIG}"
          }
          
          // Establecer todos los valores automáticamente según la configuración
          env.VM_NAME = selectedConfig.name
          env.VM_REGION = selectedConfig.region
          env.VM_SIZE = selectedConfig.size
          env.VM_IMAGE = selectedConfig.image
          env.CLOUD_INIT_TEMPLATE = selectedConfig.cloudInitTemplate
          env.VM_COST = selectedConfig.cost
          
          echo "🔧 Configuración seleccionada: ${params.VM_CONFIG}"
          echo "📊 Tamaño de VM: ${env.VM_SIZE}"
          echo "📄 Template cloud-init: ${env.CLOUD_INIT_TEMPLATE}"
          echo "📝 Descripción: ${selectedConfig.description}"
          echo "💰 Costo estimado: ${env.VM_COST}"
          
          // Mostrar información importante sobre la acción
          if (params.ACTION == 'create') {
            echo "⚠️  ATENCIÓN: Se creará una nueva VM con las siguientes características:"
            echo "   • Nombre: ${env.VM_NAME}"
            echo "   • Región: ${env.VM_REGION}"
            echo "   • Tamaño: ${env.VM_SIZE}"
            echo "   • Imagen: ${env.VM_IMAGE}"
            echo "   • Costo estimado: ${env.VM_COST}"
          } else if (params.ACTION == 'destroy') {
            echo "⚠️  ATENCIÓN: Se eliminará la VM '${env.VM_NAME}' permanentemente"
          } else if (params.ACTION == 'rebuild') {
            echo "⚠️  ATENCIÓN: Se eliminará y recreará la VM '${env.VM_NAME}'"
          } else {
            echo "ℹ️  Solo se consultará el estado de la VM '${env.VM_NAME}'"
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
          echo "➤ Droplet: ${env.VM_NAME} (${env.VM_REGION}, ${env.VM_SIZE}, ${env.VM_IMAGE})"
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
            
            if (params.VM_CONFIG == 'ecommerce_minikube') {
              // Usar Terraform para Minikube
              echo "🚀 Usando Terraform para crear VM de Minikube..."
              
              // Crear terraform.tfvars dinámicamente
              writeFile file: 'terraform/minikube-vm/terraform.tfvars', text: """do_token   = "${DO_TOKEN}"
vm_name    = "${env.VM_NAME}"
region     = "${env.VM_REGION}"
size       = "${env.VM_SIZE}"
vm_password = "${VM_PASSWORD}"
"""

              if (action == 'create') {
                sh """
set -e
echo "🔧 Configurando Terraform para Minikube..."
cd terraform/minikube-vm

# Inicializar Terraform si es necesario
if [ ! -d ".terraform" ]; then
  echo "📦 Inicializando Terraform..."
  terraform init
fi

# Aplicar configuración de Terraform
echo "🚀 Aplicando configuración de Terraform..."
terraform apply -auto-approve

# Obtener IP de la VM creada
VM_IP=\$(terraform output -raw droplet_ip)
echo "🌐 VM IP: \$VM_IP"
echo "VM_IP=\$VM_IP" > ../../vm-info.properties
"""
              } else if (action == 'rebuild') {
                sh """
set -e
echo "🔁 Reconstruyendo VM de Minikube con Terraform..."
cd terraform/minikube-vm

# Destruir VM existente
echo "🗑️ Destruyendo VM existente..."
terraform destroy -auto-approve || true

# Crear nueva VM
echo "🚀 Creando nueva VM..."
terraform apply -auto-approve

# Obtener IP de la VM creada
VM_IP=\$(terraform output -raw droplet_ip)
echo "🌐 VM IP: \$VM_IP"
echo "VM_IP=\$VM_IP" > ../../vm-info.properties
"""
              } else if (action == 'destroy') {
                sh """
set -e
echo "🗑️ Destruyendo VM de Minikube con Terraform..."
cd terraform/minikube-vm
terraform destroy -auto-approve
"""
              } else {
                echo "ℹ️ Acción de solo estado - consultando estado de Terraform..."
                sh """
cd terraform/minikube-vm
terraform show || echo "No hay recursos de Terraform"
"""
              }
            } else {
              // Usar método tradicional para VM estándar
              echo "🚀 Usando método tradicional para VM estándar..."
              
              def commonEnv = [
                "NAME=${env.VM_NAME}",
                "REGION=${env.VM_REGION}",
                "SIZE=${env.VM_SIZE}",
                "IMAGE=${env.VM_IMAGE}",
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
    }

    stage('Fetch Metadata') {
      steps {
        withCredentials([string(credentialsId: 'digitalocean-token', variable: 'DO_TOKEN')]) {
          script {
            def ip = ""
            if (params.ACTION != 'destroy') {
              if (params.VM_CONFIG == 'ecommerce_minikube') {
                // Para Minikube, obtener IP desde Terraform
                try {
                  ip = sh(
                    script: """
                      set -e
                      cd terraform/minikube-vm
                      terraform output -raw droplet_ip 2>/dev/null || echo ""
                    """,
                    returnStdout: true
                  ).trim()
                } catch (Exception e) {
                  echo "⚠️ No se pudo obtener IP desde Terraform: ${e.getMessage()}"
                  ip = ""
                }
              } else {
                // Para VM estándar, usar método tradicional
                ip = sh(
                  script: """
                    set -e
                    curl -sS -H "Authorization: Bearer ${DO_TOKEN}" "https://api.digitalocean.com/v2/droplets?per_page=200" \\
                      | jq -r --arg NAME "${env.VM_NAME}" '.droplets[] | select(.name==\$NAME) | .networks.v4[] | select(.type=="public") | .ip_address' \\
                      | head -n1
                  """,
                  returnStdout: true
                ).trim()
              }
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

            writeFile file: env.PROPERTIES_FILE, text: """VM_NAME=${env.VM_NAME}
DROPLET_IP=${env.DROPLET_IP ?: ''}
ACTION=${params.ACTION}
VM_CONFIG=${params.VM_CONFIG}
REGION=${env.VM_REGION}
SIZE=${env.VM_SIZE}
IMAGE=${env.VM_IMAGE}
CLOUD_INIT_TEMPLATE=${env.CLOUD_INIT_TEMPLATE}
COST=${env.VM_COST}
METHOD=${params.VM_CONFIG == 'ecommerce_minikube' ? 'terraform' : 'traditional'}
"""

            def triggeredBy = env.BUILD_USER_ID ?: env.BUILD_USER ?: env.BUILD_TAG ?: 'jenkins'

            writeFile file: env.JENKINS_ENV_FILE, text: """VM_NAME=${env.VM_NAME}
DROPLET_IP=${env.DROPLET_IP ?: ''}
VM_IP_ADDRESS=${env.VM_IP_ADDRESS ?: ''}
ACTION=${params.ACTION}
VM_CONFIG=${params.VM_CONFIG}
BUILD_NUMBER=${env.BUILD_NUMBER}
JOB_NAME=${env.JOB_NAME}
TRIGGERED_BY=${triggeredBy}
TIMESTAMP=${new Date().format('yyyy-MM-dd HH:mm:ss')}
METHOD=${params.VM_CONFIG == 'ecommerce_minikube' ? 'terraform' : 'traditional'}
"""

            if (params.ARCHIVE_METADATA) {
              archiveArtifacts artifacts: "${env.PROPERTIES_FILE},${env.JENKINS_ENV_FILE}", fingerprint: true
            }
          }
        }
      }
    }

    stage('Configure Minikube with Ansible') {
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

            echo "🚀 Configurando Minikube con Ansible en ${targetIp}..."

            // Esperar a que SSH esté disponible
            sh """
set -e

echo "⏳ Esperando que SSH esté disponible en ${targetIp}..."
for i in \$(seq 1 30); do
  if sshpass -p "${VM_PASSWORD}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@${targetIp} "echo SSH ready" >/dev/null 2>&1; then
    echo "✅ SSH disponible en ${targetIp}"
    break
  fi
  echo "   reintentando (\$i/30)..."
  sleep 10
done

# Configurar con Ansible
echo "🎭 Configurando con Ansible..."
cd ansible/minikube-vm

# Crear inventario dinámico
cat > inventory.ini << EOF
[minikube_vm]
${targetIp} ansible_user=jenkins ansible_password=${VM_PASSWORD}
EOF

# Configurar ansible.cfg
cat > ansible.cfg << EOF
[defaults]
host_key_checking = False
inventory = inventory.ini
remote_user = jenkins
private_key_file = 
ansible_ssh_pass = ${VM_PASSWORD}

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF

# Ejecutar playbook
echo "🚀 Ejecutando playbook de Ansible..."
ansible-playbook -i inventory.ini playbook.yml

echo "✅ Minikube configurado exitosamente con Ansible"
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
for i in \$(seq 1 60); do
  if sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@${targetIp} "echo VM ready" >/dev/null 2>&1; then
    READY=1
    break
  fi
  echo "   reintentando (\$i/60)..."
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
  
  # Verificar si gcloud está disponible
  if command -v gcloud >/dev/null 2>&1; then
    echo '✅ gcloud encontrado, configurando...'
    gcloud auth activate-service-account --key-file=\$TMP_REMOTE_CRED
    gcloud config set project '$GCP_PROJECT_ID'
    gcloud auth configure-docker us-docker.pkg.dev --quiet || true
    gcloud auth configure-docker gcr.io --quiet || true
    echo '✅ gcloud configurado para el proyecto $GCP_PROJECT_ID'
  else
    echo '⚠️  gcloud no está disponible en la VM'
    echo 'ℹ️  La VM está lista pero sin acceso a Google Cloud'
    echo 'ℹ️  Esto puede ser normal si cloud-init aún está ejecutándose'
  fi
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
• Droplet          : ${env.VM_NAME}
• Región / Size    : ${env.VM_REGION} / ${env.VM_SIZE}
• Imagen           : ${env.VM_IMAGE}
• Costo estimado   : ${env.VM_COST}
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
