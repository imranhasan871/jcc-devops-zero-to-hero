pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    environment {
        REGISTRY  = 'your-registry.io/jcc'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        // 'kubeconfig' is a Jenkins Secret File credential containing your kubeconfig
        KUBECONFIG = credentials('kubeconfig')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install') {
            steps {
                dir('backend') { sh 'npm ci' }
            }
        }

        stage('Lint') {
            steps {
                dir('backend') { sh 'npm run lint' }
            }
        }

        stage('Test') {
            steps {
                dir('backend') { sh 'npm test' }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Backend')  { steps { sh "docker build -t ${REGISTRY}/backend:${IMAGE_TAG} ./backend"   } }
                stage('Frontend') { steps { sh "docker build -t ${REGISTRY}/frontend:${IMAGE_TAG} ./frontend" } }
                stage('Database') { steps { sh "docker build -t ${REGISTRY}/database:${IMAGE_TAG} ./database" } }
            }
        }

        stage('Security Scan') {
            steps {
                // TODO: add trivy scan here
                echo "TODO: add trivy scan here"
            }
        }

        stage('Push Images') {
            when { branch 'main' }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'registry-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login your-registry.io -u $DOCKER_USER --password-stdin'
                    sh "docker push ${REGISTRY}/backend:${IMAGE_TAG}"
                    sh "docker push ${REGISTRY}/frontend:${IMAGE_TAG}"
                    sh "docker push ${REGISTRY}/database:${IMAGE_TAG}"
                    sh 'docker logout your-registry.io'
                }
            }
        }

        stage('Deploy to Dev') {
            when { branch 'main' }
            steps {
                echo "Deploying build ${IMAGE_TAG} to jcc-dev namespace..."
                sh """
                    kubectl set image deployment/backend \
                        backend=${REGISTRY}/backend:${IMAGE_TAG} \
                        -n jcc-dev
                    kubectl set image deployment/frontend \
                        frontend=${REGISTRY}/frontend:${IMAGE_TAG} \
                        -n jcc-dev
                    kubectl rollout status deployment/backend  -n jcc-dev --timeout=120s
                    kubectl rollout status deployment/frontend -n jcc-dev --timeout=120s
                """
                echo "Dev deployment complete — run smoke tests against dev environment"
            }
        }

        stage('Approve Production Deploy') {
            when { branch 'main' }
            steps {
                // Pauses the pipeline and waits for a human to click Proceed or Abort.
                // The build stays in Jenkins and times out after 24 hours if nobody responds.
                timeout(time: 24, unit: 'HOURS') {
                    input message: "Deploy build ${IMAGE_TAG} to PRODUCTION?",
                          ok: 'Deploy to Production',
                          submitter: 'admin,release-manager'  // only these users can approve
                }
            }
        }

        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                echo "Deploying build ${IMAGE_TAG} to jcc-production namespace..."
                sh """
                    kubectl set image deployment/backend \
                        backend=${REGISTRY}/backend:${IMAGE_TAG} \
                        -n jcc-production
                    kubectl set image deployment/frontend \
                        frontend=${REGISTRY}/frontend:${IMAGE_TAG} \
                        -n jcc-production
                    kubectl rollout status deployment/backend  -n jcc-production --timeout=300s
                    kubectl rollout status deployment/frontend -n jcc-production --timeout=300s
                """
                echo "Production deployment complete!"
            }
        }
    }

    post {
        success {
            echo "Pipeline complete — build ${IMAGE_TAG} is live in production"
        }
        failure {
            echo "Pipeline FAILED at stage — production was NOT updated"
        }
        always {
            sh "docker rmi ${REGISTRY}/backend:${IMAGE_TAG} ${REGISTRY}/frontend:${IMAGE_TAG} ${REGISTRY}/database:${IMAGE_TAG} || true"
            cleanWs()
        }
    }
}
