pipeline {
    agent none

    environment {
        SONARQUBE_SERVER = 'SonarQubeServer'
        SONARQUBE_TOKEN  = credentials('sonar-token')
        DOCKER_TAG       = "${BUILD_NUMBER}"
    }

    stage('Checkout') {
        agent { label 'master-docker' }
        steps {
        cleanWs()
        checkout([
            $class: 'GitSCM',
            branches: [[name: '*/master']],
            doGenerateSubmoduleConfigurations: false,
            extensions: [[$class: 'CloneOption', depth: 1, noTags: true, shallow: true]],
            userRemoteConfigs: [[url: 'https://github.com/narendra7306/php-mysql-app.git']]
        ])
       }
    }


        stage('Run Unit Tests') {
            agent {
                docker {
                    image 'php:8.2-cli'
                    args '-u root'
                }
            }
            steps {
                sh '''
                    apt-get update && apt-get install -y git unzip zip
                    git config --global --add safe.directory $WORKSPACE

                    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
                    php composer-setup.php --install-dir=$HOME --filename=composer
                    rm composer-setup.php

                    $HOME/composer install --no-interaction --prefer-dist

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
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
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
                    image 'docker:24.0-dind'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
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
