pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQubeServer'
        SONARQUBE_TOKEN  = credentials('sonar-token')
        DOCKER_TAG       = "${BUILD_NUMBER}"
        DOCKER_HOST      = "unix:///var/run/docker.sock"

        // Docker Repositories
        PHP_IMAGE        = "narendra7306/php-app"
        MYSQL_IMAGE      = "narendra7306/mysql-backend"
    }

    stages {

        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('Run Unit Tests') {
            agent {
                docker {
                    image 'php:8.2-cli'
                    args "-u root -v \"${env.WORKSPACE}:/app\" --workdir /app"
                }
            }
            steps {
                sh '''
                    apt-get update && apt-get install -y git unzip zip
                    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
                    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
                    rm composer-setup.php
                    composer install --no-interaction --prefer-dist
                    ./vendor/bin/phpunit \
                        --coverage-clover=coverage.xml \
                        --log-junit junit-report.xml \
                        tests
                '''
            }
        }

        stage('SonarQube Analysis') {
            agent {
                docker {
                    image 'sonarsource/sonar-scanner-cli:latest'
                    args '-u root'
                }
            }
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=my-php-app \
                          -Dsonar.sources=. \
                          -Dsonar.userHome=${WORKSPACE}/.sonar \
                          -Dsonar.host.url=http://172.28.47.176:9000 \
                          -Dsonar.tests=tests \
                          -Dsonar.php.coverage.reportPaths=coverage.xml \
                          -Dsonar.exclusions=tests/** \
                          -Dsonar.php.tests.reportPath=junit-report.xml
                    '''
                }
            }
        }

        stage('Build PHP Docker Image') {
            agent {
                docker {
                    image 'docker:latest'
                    args '--entrypoint="" -u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                script {
                    sh "docker build -t ${PHP_IMAGE}:${DOCKER_TAG} -f Dockerfile.app ."
                }
            }
        }

        stage('Build MySQL Docker Image') {
            agent {
                docker {
                    image 'docker:latest'
                    args '--entrypoint=\"\" -u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                script {
                    sh "docker build -t ${MYSQL_IMAGE}:${DOCKER_TAG} -f Dockerfile.mysql ."
                }
            }
        }

        stage('Publish Docker Images') {
            agent {
                docker {
                    image 'docker:latest'
                    args '--entrypoint="" -u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    script {
                        sh """
                            echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin

                            # Push PHP image
                            docker push ${PHP_IMAGE}:${DOCKER_TAG}
                            docker tag ${PHP_IMAGE}:${DOCKER_TAG} ${PHP_IMAGE}:latest
                            docker push ${PHP_IMAGE}:latest

                            # Push MySQL image
                            docker push ${MYSQL_IMAGE}:${DOCKER_TAG}
                            docker tag ${MYSQL_IMAGE}:${DOCKER_TAG} ${MYSQL_IMAGE}:latest
                            docker push ${MYSQL_IMAGE}:latest
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
        success {
            echo "🎉 Successfully built and pushed images:"
            echo "📦 ${PHP_IMAGE}:${DOCKER_TAG} and latest"
            echo "📦 ${MYSQL_IMAGE}:${DOCKER_TAG} and latest"
        }
        failure {
            echo "❌ Build failed. Docker images were not pushed."
        }
    }
}
