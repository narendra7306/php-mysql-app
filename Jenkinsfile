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
        DOCKER_TAG      = "${BUILD_NUMBER}" 
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/narendra7306/php-mysql-app.git'
            }
        }    

        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh """
                        #tar -xvf devops-demo-1.1.tar.gz
                        sonar-scanner \
                          -Dsonar.projectKey=my-php-app \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.userHome=${WORKSPACE}/.sonar
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
