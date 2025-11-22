pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQubeServer'
        SONARQUBE_TOKEN  = credentials('sonar-token')
        DOCKER_TAG       = "${BUILD_NUMBER}"
        DOCKER_HOST      = "unix:///var/run/docker.sock"
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
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.userHome=${WORKSPACE}/.sonar \
                          -Dsonar.tests=tests \
                          -Dsonar.php.coverage.reportPaths=coverage.xml \
                          -Dsonar.php.tests.reportPath=junit-report.xml
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            agent {
                docker {
                    image 'docker:latest'
                    args '-u root'
                }
            }
            steps {
                script {
                    def imageName = "narendra7306/php-app:${DOCKER_TAG}"
                    sh "docker build -t ${imageName} -f Dockerfile.app ."
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
