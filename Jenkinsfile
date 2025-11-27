pipeline {
    agent any

    environment {
        DOCKER_TAG = "latest"
        PHP_IMAGE = "narendra7306/php-app"
        MYSQL_IMAGE = "narendra7306/mysql-backend"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Images') {
            steps {
                script {
                    sh "docker build -t ${PHP_IMAGE}:${DOCKER_TAG} -f Dockerfile ."
                    sh "docker build -t ${MYSQL_IMAGE}:${DOCKER_TAG} -f Dockerfile.mysql ."
                }
            }
        }

        stage('Trivy Scan PHP Image') {
            agent {
                docker {
                    image 'aquasec/trivy:latest'
                    args '--entrypoint="" -u root -v /var/run/docker.sock:/var/run/docker.sock -v "${env.WORKSPACE}:${env.WORKSPACE}"'
                }
            }
            steps {
                script {
                    sh """
                        mkdir -p ${WORKSPACE}/.trivy-cache
                        trivy image --exit-code 1 --severity HIGH,CRITICAL \
                        --cache-dir ${WORKSPACE}/.trivy-cache \
                        ${PHP_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }

        stage('Trivy Scan MySQL Image') {
            agent {
                docker {
                    image 'aquasec/trivy:latest'
                    args '--entrypoint="" -u root -v /var/run/docker.sock:/var/run/docker.sock -v "${env.WORKSPACE}:${env.WORKSPACE}"'
                }
            }
            steps {
                script {
                    sh """
                        mkdir -p ${WORKSPACE}/.trivy-cache
                        trivy image --exit-code 1 --severity HIGH,CRITICAL \
                        --cache-dir ${WORKSPACE}/.trivy-cache \
                        ${MYSQL_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh """
                            echo "$PASSWORD" | docker login -u "$USERNAME" --password-stdin
                            docker push ${PHP_IMAGE}:${DOCKER_TAG}
                            docker push ${MYSQL_IMAGE}:${DOCKER_TAG}
                        """
                    }
                }
            }
        }

    }

    post {
        always {
            cleanWs()
        }
    }
}
