pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    environment {
        REGISTRY  = 'your-registry.io/jcc'      // change to your registry
        IMAGE_TAG = "${env.BUILD_NUMBER}"         // unique tag per build
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Building ${env.BRANCH_NAME} @ ${env.GIT_COMMIT?.take(8)} as image tag ${IMAGE_TAG}"
            }
        }

        stage('Install') {
            steps {
                dir('backend') {
                    sh 'npm ci'
                }
            }
        }

        stage('Lint') {
            steps {
                dir('backend') {
                    sh 'npm run lint'
                }
            }
        }

        stage('Test') {
            steps {
                dir('backend') {
                    sh 'npm test'
                }
            }
        }

        // Build all three images in parallel to save time
        stage('Build Docker Images') {
            parallel {
                stage('Backend Image') {
                    steps {
                        sh "docker build -t ${REGISTRY}/backend:${IMAGE_TAG} ./backend"
                        sh "docker tag ${REGISTRY}/backend:${IMAGE_TAG} ${REGISTRY}/backend:latest"
                    }
                }
                stage('Frontend Image') {
                    steps {
                        sh "docker build -t ${REGISTRY}/frontend:${IMAGE_TAG} ./frontend"
                        sh "docker tag ${REGISTRY}/frontend:${IMAGE_TAG} ${REGISTRY}/frontend:latest"
                    }
                }
                stage('Database Image') {
                    steps {
                        sh "docker build -t ${REGISTRY}/database:${IMAGE_TAG} ./database"
                        sh "docker tag ${REGISTRY}/database:${IMAGE_TAG} ${REGISTRY}/database:latest"
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                // TODO: replace this stub with a real Trivy scan:
                //   sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --exit-code 1 --severity HIGH,CRITICAL ${REGISTRY}/backend:${IMAGE_TAG}"
                echo "TODO: add trivy scan here"
                echo "Stub: skipping security scan for now"
            }
        }

        stage('Push Images') {
            when {
                branch 'main'   // only push from the main branch
            }
            steps {
                // Jenkins Credentials Binding plugin — never puts secrets in logs
                withCredentials([usernamePassword(
                    credentialsId: 'registry-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login your-registry.io -u $DOCKER_USER --password-stdin'
                    sh "docker push ${REGISTRY}/backend:${IMAGE_TAG}"
                    sh "docker push ${REGISTRY}/backend:latest"
                    sh "docker push ${REGISTRY}/frontend:${IMAGE_TAG}"
                    sh "docker push ${REGISTRY}/frontend:latest"
                    sh "docker push ${REGISTRY}/database:${IMAGE_TAG}"
                    sh "docker push ${REGISTRY}/database:latest"
                    sh 'docker logout your-registry.io'
                }
            }
        }
    }

    post {
        success {
            echo "Build #${IMAGE_TAG} complete — images pushed to ${REGISTRY}"
        }
        failure {
            echo "Build #${IMAGE_TAG} FAILED — images NOT pushed"
        }
        always {
            // Remove local images to free disk on the Jenkins agent
            sh "docker rmi ${REGISTRY}/backend:${IMAGE_TAG} ${REGISTRY}/frontend:${IMAGE_TAG} ${REGISTRY}/database:${IMAGE_TAG} || true"
            cleanWs()
        }
    }
}
