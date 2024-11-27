pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER_NAME = 'my-eks-cluster'
        FRONTEND_DIR = 'client'
        BACKEND_DIR = 'server'
        EKS_DIR = 'k8s'
        K8S_DIR = 'infrastructure/k8s'
        BACKEND_S3_DIR = 'infrastructure/k8s/backend-s3-dynamodb'
        GIT_REPO = 'https://github.com/Mecit-tuksoy/microservice-MERN-stack-deploy.git'
        TEST_RESULT_FILE = 'file-test.txt'    
        BUILD_LOG_FILE = 'image-build-logs.txt'
        TEST_RESULT_LOG_FILE = 'application-test-results.txt'
        IMAGE_TEST_RESULT_FILE = 'test-image.txt'
        POST_GET_RESULT_FILE = 'POST-GET-test.txt'
    }
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/Mecit-tuksoy/microservice-MERN-stack-deploy.git'
            }
        }
        stage('Run Security Scans') {
            steps {
                sh '''
                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/scripts/install.sh | sh
                trivy fs --severity HIGH,CRITICAL . > ${TEST_RESULT_FILE}  
                '''
                // trivy fs --exit-code 1 --severity HIGH,CRITICAL . > ${TEST_RESULT_FILE}   (pipeline risk varsa durur.)
            }
        }
        stage('Check Security Scan Results') {
            steps {
                script {
                    if (fileExists(env.TEST_RESULT_FILE)) {
                        def scanResults = readFile(env.TEST_RESULT_FILE)
                        if (scanResults.contains("CRITICAL") || scanResults.contains("HIGH")) {
                            echo "Warning: Security scan found vulnerabilities. Please address them."
                        }
                        // if (scanResults.contains("CRITICAL") || scanResults.contains("HIGH")) {
                        //     error("Security scan failed. Please fix vulnerabilities.")
                        // }
                    }
                }
            }
        }
        stage('Apply Terraform (Backend Resources)') {
            steps {
                dir("${BACKEND_S3_DIR}") {
                    sh 'terraform init'
                    sh 'terraform plan -out=plan.out'
                    sh 'terraform apply -auto-approve plan.out'
                }
            }
        }
        stage('Apply Terraform (EKS Cluster)') {
            steps {
                dir("${K8S_DIR}") {
                    sh 'terraform init'
                    sh 'terraform plan -out=plan.out'
                    sh 'terraform apply -auto-approve plan.out'
                }
            }
        }

        stage('Check EKS Cluster Status') {
            steps {
                script {
                    def eksStatus = sh(
                        script: "aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --query 'cluster.status' --output text",
                        returnStdout: true
                    ).trim()
                    
                    while (eksStatus != "ACTIVE") {
                        echo "EKS Cluster is not active yet, waiting..."
                        sleep(30) // 30 saniye bekle
                        eksStatus = sh(
                            script: "aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --query 'cluster.status' --output text",
                            returnStdout: true
                        ).trim()
                    }
                    echo "EKS Cluster is active!"
                }
            }
        }
        stage('Deploy Metrics Server and Node Exporter') {
            steps {
                script {
                    sh '''
                    aws eks update-kubeconfig --region ${env.AWS_REGION} --name ${env.EKS_CLUSTER_NAME}
                    sleep 30
                    
                    # Metrics Server yükle
                    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
                    
                    # Helm deposu ekle
                    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
                    helm repo update
                    
                    # Node Exporter yükle
                    helm install node-exporter prometheus-community/prometheus-node-exporter --namespace kube-system
                    '''
                }
            }
        }
        stage('Retrieve Node Public IP for Prometheus') {
            steps {
                script {
                    def publicIPs = sh(
                        script: "kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type==\"ExternalIP\")].address}'",
                        returnStdout: true
                    ).trim().split(" ")
                    writeFile file: 'public_ips.txt', text: publicIPs.join("\n")
                    echo "Node Public IPs: ${publicIPs}"
                }
            }
        }
        stage('Update Prometheus Configuration') {
            steps {
                script {
                    def publicIP = readFile('public_ips.txt').trim() // Dosyadan IP adresini oku ve boşlukları temizle
                    def prometheusTarget = "      - targets: ['${publicIP}:9100']"
                    sh """
                    echo "
                    scrape_configs:
                    - job_name: 'eks'
                        static_configs:
                        ${prometheusTarget}
                    " | sudo tee -a /etc/prometheus/prometheus.yml
                    
                    sudo systemctl restart prometheus
                    """
                }
            }
        }

        
        stage('Update Configuration Files') {
            steps {
                script {
                    // EKS Cluster'dan Worker Node Public IP'yi al
                    def workerNodeIP = sh(
                        script: "aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --query 'cluster.resourcesVpcConfig.endpointPublicAccess' --output text",
                        returnStdout: true
                    ).trim()
                    
                    // Değişiklik yapılacak dosyaların listesi
                    def filesToUpdate = [
                        "${FRONTEND_DIR}/src/components/create.js",
                        "${FRONTEND_DIR}/src/components/edit.js",
                        "${FRONTEND_DIR}/src/components/healthcheck.js",
                        "${FRONTEND_DIR}/src/components/recordList.js",
                        "${FRONTEND_DIR}/cypress/integration/endToEnd.spec.js"
                    ]
                    
                    // Her dosyada <worker-node-public-ip> ifadesini değiştir
                    filesToUpdate.each { file ->
                        sh "sed -i 's|<worker-node-public-ip>|${workerNodeIP}|g' ${file}"
                    }
                }
            }
        }
        stage('Tag, Build, and Test Application') {
            steps {
                sh '''
                # Build and tag Docker images
                docker build -t mecit35/mern-project-frontend:latest ${FRONTEND_DIR} > ${BUILD_LOG_FILE}
                docker build -t mecit35/mern-project-backend:latest ${BACKEND_DIR} >> ${BUILD_LOG_FILE}

                # Run tests for backend
                docker run --rm mecit35/mern-project-backend:latest npm test > ${TEST_RESULT_LOG_FILE}

                # Run tests for frontend
                docker run --rm mecit35/mern-project-frontend:latest npm test >> ${TEST_RESULT_LOG_FILE}
                '''
            }
        }
        stage('Run Security Scans on Docker Images') {
            steps {
                sh '''
                # Scan the frontend and backend Docker images for vulnerabilities and save the results
                trivy image --severity HIGH,CRITICAL --no-progress --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-frontend:latest
                trivy image --severity HIGH,CRITICAL --no-progress --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-backend:latest
                '''
                // trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-frontend:latest       (pipeline risk varsa durur.)
                // trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-backend:latest         (pipeline risk varsa durur.)
            }
        }
        stage('Push Docker Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push mecit35/mern-project-frontend:latest
                    docker push mecit35/mern-project-backend:latest
                    '''
                }
            }
        }
        stage('Configure EKS and Deploy Resources') {
            steps {
                sh '''
                kubectl apply -f ${EKS_DIR}
                '''
            }
        }
        stage('Test Application Deployment') {
            steps {
                script {
                    def workerNodeIP = sh(
                        script: "kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"ExternalIP\")].address}'",
                        returnStdout: true
                    ).trim()
                    
                    sh """
                    curl -X POST http://${workerNodeIP}:30001/record   -H "Content-Type: application/json" -d '{"name": "mecit", "position": "DevOps", "level": "Middle"}' >> ${POST_GET_RESULT_FILE}
                    curl http://${workerNodeIP}:30002 >> ${POST_GET_RESULT_FILE}
                    """
                }
            }
        }
    }
    post {
     always {
        emailext attachLog: true,
            subject: "'${currentBuild.result}'",
            body: "Project: ${env.JOB_NAME}<br/>" +
                "Build Number: ${env.BUILD_NUMBER}<br/>" +
                "URL: ${env.BUILD_URL}<br/>",
            to: 'mecit.tuksoy@gmail.com',
            attachmentsPattern: "${TEST_RESULT_FILE},${POST_GET_RESULT_FILE},${BUILD_LOG_FILE},${TEST_RESULT_LOG_FILE},${IMAGE_TEST_RESULT_FILE}"
        }
    }
}
       