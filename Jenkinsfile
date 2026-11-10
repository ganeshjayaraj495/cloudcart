pipeline {
    agent any
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t cloudcart-app .'
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    // 1. Securely log into Docker Hub
                    sh "echo '${DOCKER_PASS}' | docker login -u '${DOCKER_USER}' --password-stdin"
                    
                    // 2. Tag local image with your Docker Hub repo and build number
                    sh "docker tag cloudcart-app ganesh495/cloudcart:${env.BUILD_NUMBER}"
                    sh "docker tag cloudcart-app ganesh495/cloudcart:latest"
                    
                    // 3. Push both tags to Docker Hub
                    sh "docker push ganesh495/cloudcart:${env.BUILD_NUMBER}"
                    sh "docker push ganesh495/cloudcart:latest"
                }
            }
        }
        stage('Run Container') {
            steps {
                sh 'docker stop cloudcart || true'
                sh 'docker rm cloudcart || true'
                // Run container using your pushed image from Docker Hub
                sh 'docker run -d --name cloudcart -p 5000:5000 ganesh495/cloudcart:latest'
            }
        }
    }
}
