pipeline {
    agent any
    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t cloudcart-app .'
            }
        }
        stage('Deploy Container') {
            steps {
                sh '''
                    # Stop and remove old container if it exists
                    docker stop cloudcart-container || true
                    docker rm cloudcart-container || true
                    
                    # Run the new container, mapping port 5000
                    docker run -d -p 5000:5000 --name cloudcart-container cloudcart-app
                '''
            }
        }
    }
}
