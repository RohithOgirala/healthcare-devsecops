pipeline {
    agent any
    environment {
        KUBECONFIG = '/var/jenkins_home/.kube/config'
        IMAGE = "carewell-app:b${BUILD_NUMBER}"
        TRIVY = 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v jenkins_home:/var/jenkins_home aquasec/trivy'
    }
    stages {
        stage('Checkout') { steps { checkout scm } }
        stage('Secret Scan') {
            steps { sh '$TRIVY fs --scanners secret --exit-code 1 $WORKSPACE' }
        }
        stage('Misconfiguration Scan') {
            steps { sh '$TRIVY config --exit-code 0 $WORKSPACE' }
        }
        stage('Build Image') { steps { sh 'docker build -t $IMAGE .' } }
        stage('Image Vulnerability Scan') {
            steps { sh '$TRIVY image --severity HIGH,CRITICAL --exit-code 0 $IMAGE' }
        }
        stage('Security Gate') {
            steps { sh '$TRIVY image --severity CRITICAL --ignore-unfixed --exit-code 1 $IMAGE' }
        }
        stage('Load Image to Cluster') {
            steps { sh 'docker save $IMAGE | docker exec -i desktop-control-plane ctr -n k8s.io images import -' }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f k8s/'
                sh 'kubectl -n healthcare set image deployment/carewell carewell=$IMAGE'
                sh 'kubectl -n healthcare rollout status deployment/carewell --timeout=120s'
            }
        }
        stage('Verify') {
            steps { sh 'kubectl -n healthcare get pods,svc' }
        }
    }
    post {
        success { echo 'CareWell DevSecOps pipeline passed all security checks and deployed!' }
        failure { echo 'Pipeline blocked - fix security findings before deploying.' }
    }
}
