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
        stage('Push to AWS ECR') {
            steps {
                script {
                    // Define your AWS details (using your Account ID: 695945476130)
                    def awsAccount = '695945476130'
                    def region = 'us-east-1' // Change to your AWS Region (e.g., us-west-2, ap-south-1)
                    def repoName = 'cloudcart'
                    def imageTag = "${env.BUILD_NUMBER}"
                    
                    // 1. Authenticate Docker with AWS ECR
                    sh "aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${awsAccount}.dkr.ecr.${region}.amazonaws.com"
                    
                    // 2. Tag local image with ECR repository URI (using build number and latest tag)
                    sh "docker tag cloudcart-app ${awsAccount}.dkr.ecr.${region}.amazonaws.com/${repoName}:${imageTag}"
                    sh "docker tag cloudcart-app ${awsAccount}.dkr.ecr.${region}.amazonaws.com/${repoName}:latest"
                    
                    // 3. Push both tags to ECR
                    sh "docker push ${awsAccount}.dkr.ecr.${region}.amazonaws.com/${repoName}:${imageTag}"
                    sh "docker push ${awsAccount}.dkr.ecr.${region}.amazonaws.com/${repoName}:latest"
                }
            }
        }
        stage('Run Container') {
            steps {
                sh 'docker stop cloudcart || true'
                sh 'docker rm cloudcart || true'
                sh 'docker run -d --name cloudcart -p 5000:5000 695945476130.dkr.ecr.us-east-1.amazonaws.com/cloudcart:latest'
            }
        }
    }
}
