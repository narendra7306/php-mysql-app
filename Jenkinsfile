pipeline {
    agent any

    environment {
        SONARQUBE_ENV = 'MySonarQube'  
    }

    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: 'github-cred', 
                    url: 'https://github.com/narendra7306/php-mysql-app.git', branch: 'master'
            }
        }


        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh """
                        sonar-scanner \
                          -Dsonar.projectKey=my-php-app \
                          -Dsonar.projectName="My PHP Application" \
                          -Dsonar.sources=. \
                          -Dsonar.php.coverage.reportPaths=coverage.xml \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_AUTH_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}


