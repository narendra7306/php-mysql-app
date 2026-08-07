pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQubeServer'
        SONARQUBE_TOKEN  = credentials('sonar-token')
        VERSION          = "v${BUILD_NUMBER}.0.0"
        DOCKER_HOST      = "unix:///var/run/docker.sock"
        DOCKER_NAMESPACE = "narendra7306"
        PHP_IMAGE        = "${DOCKER_NAMESPACE}/php-app"
        MYSQL_IMAGE      = "${DOCKER_NAMESPACE}/mysql-backend"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_BUILDKIT = "1"
        KUBECONFIG = '/var/jenkins_home/.kube/config'
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
                    args "-u root -v ${WORKSPACE}:/app --workdir /app"
                }
            }

            steps {
                sh '''
                    set -eux

                    apt-get update

                    apt-get install -y \
                        git \
                        unzip \
                        zip \
                        curl \
                        $PHPIZE_DEPS

                    curl -sS https://getcomposer.org/installer | php -- \
                        --install-dir=/usr/local/bin \
                        --filename=composer

                    docker-php-ext-install mysqli
                    
                    pecl install xdebug

                    docker-php-ext-enable xdebug

                    export XDEBUG_MODE=coverage

                    git config --global --add safe.directory /app
                    git config --global --add safe.directory "$WORKSPACE"

                    php -v

                    php -m | grep xdebug

                    composer install --no-interaction --prefer-dist

                    XDEBUG_MODE=coverage ./vendor/bin/phpunit \
                        --configuration phpunit.xml \
                        --coverage-clover=coverage.xml \
                        --log-junit=junit-report.xml \

                    echo "===== Reports ====="

                    ls -lh coverage.xml
                    ls -lh junit-report.xml

                    head -20 coverage.xml
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
                          -Dsonar.projectKey=php-app \
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
                    docker build -t ${PHP_IMAGE}:${VERSION} -f Dockerfile.app .
                    docker build -t ${MYSQL_IMAGE}:${VERSION} -f Dockerfile.mysql .
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
                                ${PHP_IMAGE}:${VERSION} \
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
                                --ignorefile .trivyignore \
                                --severity HIGH,CRITICAL \
                                --format json \
                                --no-progress \
                                ${MYSQL_IMAGE}:${VERSION} \
                                | tee trivy-reports/mysql-image-report.json

                        echo "✔ Checking for CRITICAL vulnerabilities in MySQL image..."

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
                    sh '''
                        echo "$PASSWORD" | docker login -u "$USERNAME" --password-stdin

                        docker push ${PHP_IMAGE}:${VERSION}
                        docker tag ${PHP_IMAGE}:${VERSION} ${PHP_IMAGE}:latest
                        docker push ${PHP_IMAGE}:latest

                        docker push ${MYSQL_IMAGE}:${VERSION}
                        docker tag ${MYSQL_IMAGE}:${VERSION} ${MYSQL_IMAGE}:latest
                        docker push ${MYSQL_IMAGE}:latest
                    '''
                }
            }
        }
    


        stage('Update Helm Repo') {

            agent {
                docker {
                    image 'python:3.12'
                    args '-u root'
                }
            }

            steps {

                sh '''
                    apt-get update
                    apt-get install -y git
                    pip install --no-cache-dir pyyaml
                '''

                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-creds',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )
                ]) {

                    sh """
                    python3 deploy.py \
                    --repo-url https://${GIT_USER}:${GIT_TOKEN}@github.com/narendra7306/php-mysql-app.git \
                    --php-image ${PHP_IMAGE} \
                    --mysql-image ${MYSQL_IMAGE} \
                    --build-number $BUILD_NUMBER
                    """

                }
            }
       }

        stage('Update MySQL Data') {
            agent {
                docker {
                    image 'bitnami/kubectl:latest'
                    args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }

            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'mysql-credentials',
                        usernameVariable: 'MYSQL_USER',
                        passwordVariable: 'MYSQL_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "Checking Kubernetes access..."

                        kubectl get pods -n backend

                        echo "Finding MySQL pod..."

                        MYSQL_POD=$(kubectl get pods \
                            -n backend \
                            -l app.kubernetes.io/instance=mysql \
                            -o jsonpath='{.items[0].metadata.name}')

                        echo "MySQL Pod: $MYSQL_POD"

                        echo "Updating MySQL database..."

                        kubectl exec -n backend "$MYSQL_POD" -- \
                            env MYSQL_PWD="$MYSQL_PASSWORD" \
                            mysql \
                            -u"$MYSQL_USER" \
                            < database/update.sql

                        echo "MySQL update completed successfully."
                    '''
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


