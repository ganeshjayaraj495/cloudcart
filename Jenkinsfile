pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t cloudcart-app .'
            }
        }
        stage('Run Container') {
            steps {
                sh 'docker stop cloudcart || true'
                sh 'docker rm cloudcart || true'
                sh 'docker run -d --name cloudcart -p 5000:5000 cloudcart-app'
            }
        }
    }
}
