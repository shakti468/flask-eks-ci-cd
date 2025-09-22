pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '975050024946.dkr.ecr.ap-south-1.amazonaws.com/flask-eks-demo:latest'  // Replace with Terraform output
        IMAGE_TAG = "latest"
        KUBE_NAMESPACE = "flask-app"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'git@github.com:shakti468/flask-eks-ci-cd.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REPO}
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                sh "docker push ${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh """
                    # Update kubeconfig
                    aws eks --region ${AWS_REGION} update-kubeconfig --name flask-eks-cluster

                    # Apply Kubernetes manifests
                    kubectl set image deployment/flask-deployment flask-container=${ECR_REPO}:${IMAGE_TAG} -n ${KUBE_NAMESPACE}
                    kubectl rollout status deployment/flask-deployment -n ${KUBE_NAMESPACE}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment Successful!"
        }
        failure {
            echo "❌ Deployment Failed!"
        }
    }
}

