pipeline {
    agent none   // no global agent, stages define their own
    environment {
        SONARQUBE_SERVER = 'SonarQubeServer'
        SONARQUBE_TOKEN  = credentials('sonar-token')                                      
        DOCKER_TAG       = "${BUILD_NUMBER}" 
    }

    stages {
        stage('Checkout') {
            agent { label 'master-docker' }
            steps {
                git branch: 'master', url: 'https://github.com/narendra7306/php-mysql-app.git'
            }
        }    

        stage('Run Unit Tests') {
            agent {
                docker {
                    image 'php:8.2-cli'   // PHP container with CLI
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh """
                    # Install Composer (if not already present)
                    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)" 
                    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
                    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
                    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
                        >&2 echo 'ERROR: Invalid composer installer signature'
                        exit 1
                    fi
                    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
                    rm composer-setup.php

                    # Install dependencies
                    composer install --no-interaction --prefer-dist

                    # Run PHPUnit with coverage
                    ./vendor/bin/phpunit \
                        --coverage-clover=coverage.xml \
                        --log-junit junit-report.xml
                """
            }
        }

        stage('SonarQube Analysis') {
            agent {
                docker {
                    image 'sonarsource/sonar-scanner-cli:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh """
                        sonar-scanner \
                          -Dsonar.projectKey=my-php-app \
                          -Dsonar.sources=devops-demo-1.1 \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.userHome=${WORKSPACE}/.sonar \
                          -Dsonar.tests=tests \
                          -Dsonar.php.coverage.reportPaths=coverage.xml \
                          -Dsonar.php.tests.reportPath=junit-report.xml
                    """
                }
            }
        }

        stage('Build Docker Image') {
            agent {
                docker {
                    image 'docker:24.0-dind'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                script {
                    def imageName = "my-php-app:${DOCKER_TAG}"
                    sh "docker build -t ${imageName} -f Dockerfile.app ."
                }
            }
        }
    }
}
