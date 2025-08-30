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
        PHP_HOME = "/usr/bin/php" 
        COMPOSER_HOME = "/usr/local/bin/composer"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/narendra7306/php-mysql-app.git'
            }
        }


        
        stage('Build PHP Application') {
            steps {
                script {
                    echo "Installing dependencies using Composer..."
                    sh '''
                        if [ -f composer.json ]; then
                            composer install --no-interaction --no-progress --prefer-dist
                        else
                            echo "No composer.json found, skipping dependency installation."
                        fi
                    '''

                    echo "Running PHP lint..."
                    sh '''
                        find . -name "*.php" -exec php -l {} \\; | grep "Errors" || true
                    '''

                    echo "Running PHPUnit tests..."
                    sh '''
                        if [ -f phpunit.xml ] || [ -f phpunit.xml.dist ]; then
                            ./vendor/bin/phpunit --colors=always
                        else
                            echo "No PHPUnit config found, skipping tests."
                        fi
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
