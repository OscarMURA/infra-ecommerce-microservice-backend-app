pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = credentials('docker-registry-url')
        DOCKER_CREDENTIALS = credentials('docker-registry-credentials')
        SONARQUBE_URL = credentials('sonarqube-url')
        SONARQUBE_TOKEN = credentials('sonarqube-token')
        KUBECONFIG = credentials('kubeconfig-file')
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'stage', 'prod'],
            description: 'Target environment for deployment'
        )
        choice(
            name: 'ACTION',
            choices: ['deploy', 'rollback', 'setup-infrastructure'],
            description: 'Action to perform'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.BUILD_TAG = "${env.GIT_COMMIT_SHORT}-${env.BUILD_NUMBER}"
                }
            }
        }
        
        stage('Code Quality Analysis') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            sonar-scanner \
                                -Dsonar.projectKey=ecommerce-microservice \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=${SONARQUBE_URL} \
                                -Dsonar.login=${SONARQUBE_TOKEN}
                        """
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Images') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    sh """
                        docker login -u ${DOCKER_CREDENTIALS_USR} -p ${DOCKER_CREDENTIALS_PSW} ${DOCKER_REGISTRY}
                        docker build -t ${DOCKER_REGISTRY}/ecommerce-backend:${BUILD_TAG} -f docker/Dockerfile .
                        docker tag ${DOCKER_REGISTRY}/ecommerce-backend:${BUILD_TAG} ${DOCKER_REGISTRY}/ecommerce-backend:latest
                        docker push ${DOCKER_REGISTRY}/ecommerce-backend:${BUILD_TAG}
                        docker push ${DOCKER_REGISTRY}/ecommerce-backend:latest
                    """
                }
            }
        }
        
        stage('Setup Infrastructure') {
            when {
                expression { params.ACTION == 'setup-infrastructure' }
            }
            steps {
                script {
                    sh """
                        cd ansible
                        ansible-playbook -i inventory/${params.ENVIRONMENT} \
                            playbooks/main.yml \
                            -e "environment=${params.ENVIRONMENT}"
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    sh """
                        export KUBECONFIG=${KUBECONFIG}
                        kubectl apply -f kubernetes/namespace-${params.ENVIRONMENT}.yml
                        kubectl apply -f kubernetes/configmap-${params.ENVIRONMENT}.yml
                        kubectl apply -f kubernetes/secrets-${params.ENVIRONMENT}.yml
                        kubectl set image deployment/ecommerce-backend \
                            ecommerce-backend=${DOCKER_REGISTRY}/ecommerce-backend:${BUILD_TAG} \
                            -n ecommerce-${params.ENVIRONMENT}
                        kubectl rollout status deployment/ecommerce-backend \
                            -n ecommerce-${params.ENVIRONMENT} \
                            --timeout=5m
                    """
                }
            }
        }
        
        stage('Rollback') {
            when {
                expression { params.ACTION == 'rollback' }
            }
            steps {
                script {
                    sh """
                        export KUBECONFIG=${KUBECONFIG}
                        kubectl rollout undo deployment/ecommerce-backend \
                            -n ecommerce-${params.ENVIRONMENT}
                        kubectl rollout status deployment/ecommerce-backend \
                            -n ecommerce-${params.ENVIRONMENT} \
                            --timeout=5m
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    sh """
                        export KUBECONFIG=${KUBECONFIG}
                        kubectl get pods -n ecommerce-${params.ENVIRONMENT}
                        kubectl get services -n ecommerce-${params.ENVIRONMENT}
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully!"
            // Add notification logic here (Slack, email, etc.)
        }
        failure {
            echo "Pipeline failed!"
            // Add notification logic here (Slack, email, etc.)
        }
        always {
            cleanWs()
        }
    }
}
