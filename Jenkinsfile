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
                          -Dsonar.host.url=http://172.28.47.176:9000 \
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

        stage('Trivy Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p trivy-reports
                        
                        echo "🔍 Running Trivy scan..."
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -v ${WORKSPACE}/.trivy-cache:/root/.cache \
                            aquasec/trivy image --skip-version-check --severity HIGH,CRITICAL --format table php:8.1 > trivy-reports/php-image-report.txt

                        echo "✔ Trivy scan completed. Checking for HIGH/CRITICAL vulnerabilities..."

                        # Filter ONLY real vulnerability rows (Trivy tables always start with '|' character)
                        VULNS=$(grep -E "HIGH|CRITICAL" trivy-reports/php-image-report.txt | grep "^|")

                        if [ ! -z "$VULNS" ]; then
                            echo "❌ HIGH or CRITICAL vulnerabilities detected in PHP image!"
                            echo "----- Vulnerability Summary (PHP Image) -----"
                            echo "$VULNS"
                            exit 1
                        else
                            echo "✔ No HIGH or CRITICAL vulnerabilities found in PHP image."
                        fi
                    '''
                }
            }
        }



        stage('Trivy Scan MySQL Image') {
            steps {
                script {
                    echo "🔍 Scanning MySQL Image"

                    sh '''
                        mkdir -p trivy-reports

                        # Generate a single full table report
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -v ${WORKSPACE}/.trivy-cache:/root/.cache \
                            aquasec/trivy image \
                            --format table \
                            --no-progress \
                            ${MYSQL_IMAGE}:${DOCKER_TAG} > trivy-reports/mysql-image-report.txt

                        echo "✔ Trivy scan completed. Checking for HIGH/CRITICAL vulnerabilities..."

                        # Check for HIGH or CRITICAL in the report
                        if grep -E "HIGH|CRITICAL" trivy-reports/mysql-image-report.txt > /dev/null; then
                            echo "❌ HIGH or CRITICAL vulnerabilities detected in MySQL image!"
                            echo "----- Vulnerability Summary (MySQL Image) -----"
                            grep -E "HIGH|CRITICAL" trivy-reports/mysql-image-report.txt
                            exit 1
                        fi

                        echo "✔ No HIGH/CRITICAL vulnerabilities found in MySQL image."
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
            archiveArtifacts artifacts: 'trivy-reports/*.txt', fingerprint: true
            cleanWs()
        }
    }
}
