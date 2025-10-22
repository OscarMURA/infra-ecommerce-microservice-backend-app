pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }

  parameters {
    choice(name: 'ACTION', choices: ['create', 'rebuild', 'destroy', 'status'], description: 'Acción a ejecutar sobre la VM')
    string(name: 'VM_NAME', defaultValue: 'ecommerce-integration-runner', description: 'Nombre del droplet en DigitalOcean')
    string(name: 'VM_REGION', defaultValue: 'nyc3', description: 'Región donde se creará el droplet')
    string(name: 'VM_SIZE', defaultValue: 's-1vcpu-2gb', description: 'Plan/tamaño de la VM')
    string(name: 'VM_IMAGE', defaultValue: 'ubuntu-22-04-x64', description: 'Imagen base a utilizar')
    booleanParam(name: 'ARCHIVE_METADATA', defaultValue: true, description: 'Publicar droplet.properties y jenkins-env.properties como artefactos')
  }

  environment {
    INFRA_DIR = "infra/digitalocean-vm"
    PROPERTIES_FILE = "droplet.properties"
    JENKINS_ENV_FILE = "jenkins-env.properties"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          echo "📦 Workspace: ${env.WORKSPACE}"
          echo "➤ Acción: ${params.ACTION}"
          echo "➤ Droplet: ${params.VM_NAME} (${params.VM_REGION}, ${params.VM_SIZE}, ${params.VM_IMAGE})"
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
              "SIZE=${params.VM_SIZE}",
              "IMAGE=${params.VM_IMAGE}"
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
REGION=${params.VM_REGION}
SIZE=${params.VM_SIZE}
IMAGE=${params.VM_IMAGE}
"""

            def triggeredBy = env.BUILD_USER_ID ?: env.BUILD_USER ?: env.BUILD_TAG ?: 'jenkins'

            writeFile file: env.JENKINS_ENV_FILE, text: """VM_NAME=${params.VM_NAME}
DROPLET_IP=${env.DROPLET_IP ?: ''}
VM_IP_ADDRESS=${env.VM_IP_ADDRESS ?: ''}
ACTION=${params.ACTION}
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

    stage('Summary') {
      steps {
        script {
          def ip = env.DROPLET_IP ?: 'N/A'
          echo """
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Jenkins_Create_VM Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Acción ejecutada : ${params.ACTION.toUpperCase()}
• Droplet          : ${params.VM_NAME}
• Región / Size    : ${params.VM_REGION} / ${params.VM_SIZE}
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
