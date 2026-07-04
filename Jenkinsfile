pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQubeServer'
        SONARQUBE_TOKEN  = credentials('sonar-token')
        DOCKER_TAG       = "${BUILD_NUMBER}"
        DOCKER_HOST      = "unix:///var/run/docker.sock"

        DOCKER_NAMESPACE = "narendra7306"
        PHP_IMAGE        = "${DOCKER_NAMESPACE}/php-app"
        MYSQL_IMAGE      = "${DOCKER_NAMESPACE}/mysql-backend"

        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_BUILDKIT = "1"
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
                    ./vendor/bin/phpunit --coverage-clover=coverage.xml --log-junit junit-report.xml tests
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
                          -Dsonar.host.url=http://172.17.0.3:9000 \
                          -Dsonar.tests=tests \
                          -Dsonar.php.coverage.reportPaths=coverage.xml \
                          -Dsonar.exclusions=tests/** \
                          -Dsonar.php.tests.reportPath=junit-report.xml
                    '''
                }
            }
        }

        stage('Build Docker Images') {
            agent {
                docker {
                    image 'docker:latest'
                    args '--entrypoint="" -u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh """
                    docker build -t ${PHP_IMAGE}:${DOCKER_TAG} -f Dockerfile.app .
                    docker build -t ${MYSQL_IMAGE}:${DOCKER_TAG} -f Dockerfile.mysql .
                """
            }
        }

        stage('Trivy Scan PHP Image') {
            steps {
                script {
                    echo "🔍 Scanning PHP Image (TABLE + immediate fail)..."

                    // Run the scan normally and save report
                    sh '''
                        mkdir -p trivy-reports

                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -v ${WORKSPACE}/.trivy-cache:/root/.cache \
                            -v ${WORKSPACE}/trivy-reports:/reports \
                            aquasec/trivy image \
                                --severity HIGH,CRITICAL \
                                --ignore-unfixed \
                                --format json \
                                --no-progress \
                                ${PHP_IMAGE}:${DOCKER_TAG} \
                                | tee trivy-reports/php-image-report.json
                    '''

                    // 🔥 Fail the pipeline if HIGH or CRITICAL found in report
                    sh '''
                        if grep -qE "HIGH|CRITICAL" trivy-reports/php-image-report.json; then
                            echo "❌ HIGH/CRITICAL vulnerabilities found in PHP image!"
                            exit 1
                        else
                            echo "✅ No HIGH/CRITICAL vulnerabilities found."
                        fi
                    '''
                }
            }
        }




        stage('Trivy Scan MySQL Image') {
            steps {
                script {
                    echo "🔍 Scanning MySQL Image (TABLE format)..."

                    sh '''
                        mkdir -p trivy-reports

                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -v ${WORKSPACE}/.trivy-cache:/root/.cache \
                            -v ${WORKSPACE}/trivy-reports:/reports \
                            aquasec/trivy image \
                                --format json \
                                --no-progress \
                                ${MYSQL_IMAGE}:${DOCKER_TAG} \
                                | tee trivy-reports/mysql-image-report.json

                        echo "✔ Checking for HIGH/CRITICAL vulnerabilities in MySQL image..."

                        if grep -qE "CRITICAL" trivy-reports/mysql-image-report.json > /dev/null; then
                            echo "❌ Critical vulnerabilities detected in MySQL image!"
                            grep -qE "CRITICAL" trivy-reports/mysql-image-report.json
                            exit 1
                        fi

                        echo "✔ No CRITICAL vulnerabilities found in MySQL image."
                    '''
                }
            }
        }




        stage('Push Docker Images') {
            agent {
                docker {
                    image 'docker:latest'
                    args '--entrypoint="" -u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "$PASSWORD" | docker login -u "$USERNAME" --password-stdin

                        docker push ${PHP_IMAGE}:${DOCKER_TAG}
                        docker tag ${PHP_IMAGE}:${DOCKER_TAG} ${PHP_IMAGE}:latest
                        docker push ${PHP_IMAGE}:latest

                        docker push ${MYSQL_IMAGE}:${DOCKER_TAG}
                        docker tag ${MYSQL_IMAGE}:${DOCKER_TAG} ${MYSQL_IMAGE}:latest
                        docker push ${MYSQL_IMAGE}:latest
                    """
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-reports/*.json', fingerprint: true
            cleanWs()
        }
    }
}
