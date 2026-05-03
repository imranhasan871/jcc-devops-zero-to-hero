pipeline {
    agent any

    options {
        // Keep only last 10 builds to save disk space
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Fail the build if it runs longer than 30 minutes
        timeout(time: 30, unit: 'MINUTES')
        // Don't run concurrent builds on the same branch
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Building branch: ${env.BRANCH_NAME}, commit: ${env.GIT_COMMIT?.take(8)}"
            }
        }

        stage('Install') {
            steps {
                dir('backend') {
                    // npm ci is faster and stricter than npm install — uses package-lock.json exactly
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
            post {
                always {
                    // Publish test results if JUnit XML is generated
                    // Requires the JUnit plugin in Jenkins
                    echo 'Test stage complete — check console output for results'
                }
            }
        }
    }

    post {
        success {
            echo "Build #${env.BUILD_NUMBER} passed on branch ${env.BRANCH_NAME}"
        }
        failure {
            echo "Build #${env.BUILD_NUMBER} FAILED on branch ${env.BRANCH_NAME} — check logs above"
        }
        always {
            // Clean up workspace to save disk space on the Jenkins agent
            cleanWs()
        }
    }
}
