pipeline {
    agent any

    environment {
        DOCKER_TAG = "latest"
        PHP_IMAGE = "narendra7306/php-app"
        MYSQL_IMAGE = "narendra7306/mysql-backend"
        DOCKER_BUILDKIT = "1"                         // Enable modern Docker builder
        TRIVY_CACHE = "${WORKSPACE}/.trivy-cache"     // Shared cache
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    sh '''
                        echo "📌 Checking required Dockerfiles..."
                        [ -f Dockerfile ] || { echo "❌ ERROR: Dockerfile missing!"; exit 1; }
                        [ -f Dockerfile.mysql ] || { echo "❌ ERROR: Dockerfile.mysql missing!"; exit 1; }

                        echo "🚀 Building PHP Docker Image..."
                        docker build -t ${PHP_IMAGE}:${DOCKER_TAG} -f Dockerfile .

                        echo "🚀 Building MySQL Docker Image..."
                        docker build -t ${MYSQL_IMAGE}:${DOCKER_TAG} -f Dockerfile.mysql .
                    '''
                }
            }
        }

        stage('Trivy Vulnerability Scan') {
            agent {
                docker {
                    image 'aquasec/trivy:latest'
                    args """--entrypoint="" -v /var/run/docker.sock:/var/run/docker.sock -v ${WORKSPACE}:${WORKSPACE}"""
                }
            }
            steps {
                script {
                    sh '''
                        mkdir -p ${TRIVY_CACHE}
                        echo "🔍 Scanning PHP Image with Trivy..."
                        trivy image --exit-code 1 --severity HIGH,CRITICAL \
                            --cache-dir ${TRIVY_CACHE} \
                            ${PHP_IMAGE}:${DOCKER_TAG} || exit 1

                        echo "🔍 Scanning MySQL Image with Trivy..."
                        trivy image --exit-code 1 --severity HIGH,CRITICAL \
                            --cache-dir ${TRIVY_CACHE} \
                            ${MYSQL_IMAGE}:${DOCKER_TAG} || exit 1
                    '''
                }
            }
        }

        stage('Push Images to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                                      usernameVariable: 'USERNAME',
                                                      passwordVariable: 'PASSWORD')]) {
                        sh '''
                            echo "🔐 Authenticating with Docker Hub..."
                            echo "$PASSWORD" | docker login -u "$USERNAME" --password-stdin
                            
                            echo "⬆️ Pushing PHP Image..."
                            docker push ${PHP_IMAGE}:${DOCKER_TAG}

                            echo "⬆️ Pushing MySQL Image..."
                            docker push ${MYSQL_IMAGE}:${DOCKER_TAG}
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            echo '🧹 Workspace cleaned!'
        }
        success {
            echo '🎉 Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Please check logs.'
        }
    }
}
