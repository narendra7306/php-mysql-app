pipeline {
    agent {
        docker {
            image 'sonarsource/sonar-scanner-cli:latest'
            label 'master-docker'   // Runs only on Jenkins master
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        SONARQUBE_SERVER = 'SonarQubeServer'
        SONARQUBE_TOKEN  = credentials('sonar-token')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/narendra7306/php-mysql-app.git'
            }
        }
    

        stage('Build TAR File') {
            steps {
                script {
                    echo "Creating tar.gz of PHP application..."
                    sh '''
                        TAR_NAME="php-mysql-app-${BUILD_NUMBER}.tar.gz"
                        tar --warning=no-file-changed -czvf ${TAR_NAME} \
                            --exclude='.git' \
                            --exclude='vendor' \
                            --exclude='*.log' \
                            --exclude='*.tmp' \
                            . || true
                        echo "Created TAR file: ${TAR_NAME}"
                    '''
                }
            }
        }

        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh """
                        tar -xvf devops-demo-1.1.tar.gz
                        sonar-scanner \
                          -Dsonar.projectKey=my-php-app \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.userHome=${WORKSPACE}/.sonar
                    """
                }
            }
        }
    }
}
