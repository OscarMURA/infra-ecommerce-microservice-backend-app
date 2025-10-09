pipeline {
  agent any

  environment {
    DO_TOKEN     = credentials('do-token')
    SSH_KEY      = credentials('ssh-key')
    SONAR_TOKEN  = credentials('sonar-token')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Provision Infra') {
      steps {
        dir('terraform') {
          sh 'terraform init'
          sh 'terraform apply -auto-approve -var-file=dev/terraform.tfvars'
          // El inventario se genera automáticamente con terraform apply
        }
      }
    }

    stage('Configure Infra') {
      steps {
        dir('ansible') {
          sh 'ansible-playbook -i inventories/dev.ini playbooks/setup-base.yml --limit all_dev_infra'
          sh 'ansible-playbook -i inventories/dev.ini playbooks/setup-base.yml --limit all_stage_infra'
          sh 'ansible-playbook -i inventories/dev.ini playbooks/setup-k8s.yml --limit all_stage_infra'
        }
      }
    }

    stage('Verify Infra') {
      steps {
        dir('ansible') {
          sh 'ansible-playbook -i inventories/dev.ini playbooks/verify-infra.yml --limit all_stage_infra'
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonar-server') {
          sh '''sonar-scanner \
            -Dsonar.projectKey=ecommerce-backend \
            -Dsonar.sources=src \
            -Dsonar.host.url=$SONAR_HOST_URL \
            -Dsonar.login=$SONAR_TOKEN'''
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }
  }

  post {
    always {
      echo 'Pipeline finalizado'
    }
  }
}
