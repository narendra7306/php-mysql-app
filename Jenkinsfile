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
                    image 'composer:2'   // PHP container with CLI
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh """
                    composer install --no-interaction --prefer-dist

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
