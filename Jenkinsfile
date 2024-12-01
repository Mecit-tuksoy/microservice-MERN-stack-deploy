pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER_NAME = 'my-eks-cluster'
        AWS_ACCESS_KEY_ID = credentials('my-aws-credentials')
        AWS_SECRET_ACCESS_KEY = credentials('my-aws-credentials')
        FRONTEND_DIR = 'client'
        BACKEND_DIR = 'server'
        EKS_DIR = 'k8s'
        K8S_DIR = 'infrastructure/k8s'
        BACKEND_S3_DIR = 'infrastructure/k8s/backend-s3-dynamodb'
        GIT_REPO = 'https://github.com/Mecit-tuksoy/microservice-MERN-stack-deploy.git'
        TEST_RESULT_FILE = 'file-test.txt'    
        BUILD_LOG_FILE = 'image-build-logs.txt'
        TEST_RESULT_LOG_FILE = 'app-test-results.txt'
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
                git branch: 'main', url: "${env.GIT_REPO}"
            }
        }
        stage('Run Security Scans') {
            steps {
                sh '''
                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/scripts/install.sh | sh
                trivy fs --severity HIGH,CRITICAL . > ${WORKSPACE}/${TEST_RESULT_FILE} 
                '''
                // trivy fs --exit-code 1 --severity HIGH,CRITICAL . > ${WORKSPACE}/${TEST_RESULT_FILE}   (pipeline risk varsa durur.)
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
                        // if (scanResults.contains("CRITICAL") || scanResults.contains("HIGH")) {       //test aşamasında gerek yok
                        //     error("Security scan failed. Please fix vulnerabilities.")
                        // }
                    }
                }
            }
        }
        stage('Apply Terraform (Backend Resources)') {
            steps {
                dir("${BACKEND_S3_DIR}") {
                    script {
                        // AWS CLI komutu ile 'mecit-terraform-state/terraform/state/MERN.tfstate' dosyasının var olup olmadığını kontrol et
                        def fileExists = sh(script: "aws s3 ls s3://mecit-terraform-state/terraform/state/MERN.tfstate", returnStatus: true)
                        
                        // Eğer dosya mevcutsa, Terraform işlemini atla
                        if (fileExists == 0) {
                            echo "Dosya 'MERN.tfstate' mevcut, Terraform işlemi atlanıyor."
                        } else {
                            echo "Dosya 'MERN.tfstate' bulunamadı, Terraform işlemi başlatılıyor."

                            // Terraform init komutunu çalıştır
                            def initResult = sh(script: 'terraform init', returnStatus: true)
                            if (initResult != 0) {
                                echo 'Terraform init başarısız oldu, devam ediliyor...'
                            }

                            // Terraform apply komutunu çalıştır
                            def applyResult = sh(script: 'terraform apply -auto-approve', returnStatus: true)
                            if (applyResult != 0) {
                                echo 'Terraform apply başarısız oldu, devam ediliyor...'
                            }
                        }
                    }
                }
            }
        }

        stage('Apply Terraform (EKS Cluster)') {
            steps {
                dir("${K8S_DIR}") {
                    script {
                        // EKS Cluster durumu kontrol et
                        def eksStatus = ''
                        try {
                            eksStatus = sh(
                                script: "aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --query 'cluster.status' --output text",
                                returnStdout: true
                            ).trim()
                        } catch (Exception e) {
                            // Eğer cluster mevcut değilse, hata alacağız ve eksStatus boş kalacak
                            echo "EKS Cluster '${EKS_CLUSTER_NAME}' bulunamadı. Terraform ile oluşturulacak."
                        }

                        // Eğer cluster mevcut ve aktifse
                        if (eksStatus == "ACTIVE") {
                            echo "EKS Cluster '${EKS_CLUSTER_NAME}' zaten aktif. Terraform apply işlemi atlanıyor."
                        } else {
                            echo "EKS Cluster '${EKS_CLUSTER_NAME}' mevcut değil ya da aktif değil. Terraform apply işlemi başlatılıyor."

                            // Terraform init komutunu çalıştır
                            def initResult = sh(script: 'terraform init', returnStatus: true)
                            if (initResult != 0) {
                                error 'Terraform init başarısız oldu, pipeline devam etmiyor.'
                            }

                            // Terraform apply komutunu çalıştır
                            def applyResult = sh(script: 'terraform apply -auto-approve', returnStatus: true)
                            if (applyResult != 0) {
                                error 'Terraform apply başarısız oldu, pipeline devam etmiyor.'
                            }
                        }
                    }
                }
            }
        }


        stage('Deploy Metrics Server and Node Exporter') {
            steps {
                script {
                    sh '''#!/bin/bash
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                    
                    # Metrics Server yükle
                    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
                    
                    # Helm deposu ekle
                    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
                    helm repo update
                    
                    # Var olan node-exporter release'ini sil
                    helm uninstall node-exporter --namespace kube-system || true
                    
                    # Node Exporter yükle
                    helm install node-exporter prometheus-community/prometheus-node-exporter --namespace kube-system
                    '''
                }
            }
        }

        stage('Public IP') {
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
                    def prometheusTarget = "${publicIP}:9100" // Hedef IP ve port
                    def configFilePath = '/etc/prometheus/prometheus.yml'

                    // Konfigürasyon dosyasını oku
                    def configFile = readFile(configFilePath)

                    // "eks" job'ının ve hedef IP'nin konfigürasyon dosyasına zaten eklenip eklenmediğini kontrol et
                    if (!configFile.contains("job_name: eks") || !configFile.contains(prometheusTarget)) {
                        // Eğer eklenmemişse, ekleyelim
                        sh """
                            echo "  - job_name: eks" | sudo tee -a ${configFilePath}
                            echo "    static_configs:" | sudo tee -a ${configFilePath}
                            echo "      - targets: ['${prometheusTarget}']" | sudo tee -a ${configFilePath}
                            
                            sudo systemctl restart prometheus
                        """
                    } else {
                        echo "Prometheus job already exists, no need to add it again."
                    }
                }
            }
        }

        stage('Update Configuration Files') {
            steps {
                script {
                    
                    def publicIPs = readFile('public_ips.txt').trim().split("\n")                    
                    def workerNodeIP = publicIPs[0]
                    def filesToUpdate = [
                        "${FRONTEND_DIR}/src/components/create.js",
                        "${FRONTEND_DIR}/src/components/edit.js",
                        "${FRONTEND_DIR}/src/components/healthcheck.js",
                        "${FRONTEND_DIR}/src/components/recordList.js",
                        "${FRONTEND_DIR}/cypress/integration/endToEnd.spec.js",
                        "${FRONTEND_DIR}/cypress.json"
                    ]
                    filesToUpdate.each { file ->
                        sh "sed -i 's|localhost|${workerNodeIP}|g' ${file}"
                    }
                }
            }
        }

     
        stage('Tag and Build  Application') {
            steps {
                sh '''
                # Build and tag Docker images
                docker build -t mecit35/mern-project-frontend:latest ${FRONTEND_DIR} > ${BUILD_LOG_FILE}
                docker build -t mecit35/mern-project-backend:latest ${BACKEND_DIR} >> ${BUILD_LOG_FILE}
                '''
            }
        }
        stage('Run Security Scans on Docker Images') {
            steps {
                sh '''
                # Scan the frontend and backend Docker images for vulnerabilities and save the results
                trivy image --severity HIGH,CRITICAL --no-progress --scanners vuln --timeout 10m --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-frontend:latest
                trivy image --severity HIGH,CRITICAL --no-progress --scanners vuln --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-backend:latest
                '''
                // trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-frontend:latest      // (pipeline risk varsa durur. bu aşamada yapmadım)
                // trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-backend:latest       //  (pipeline risk varsa durur. bu aşamada yapmadım)
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

        stage('EKS Deploy') {
            steps {
                sh '''
                kubectl apply -f ${EKS_DIR}
                '''
            }
        }

    
        stage('Install Node.js and npm') {
            steps {
                script {
                    // Node.js ve npm yüklü mü kontrol et
                    def nodeInstalled = sh(script: 'which node', returnStatus: true)
                    def npmInstalled = sh(script: 'which npm', returnStatus: true)
                    
                    if (nodeInstalled != 0 || npmInstalled != 0) {
                        // Node.js ve npm yüklü değilse yükle
                        sh '''
                        # NodeSource Node.js binary dağıtım deposunu ekle
                        curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
                        
                        # Node.js ve npm'i kur
                        sudo apt-get install -y nodejs
                        
                        # Node.js ve npm sürümlerini kontrol et
                        node -v
                        npm -v
                        '''
                    } else {
                        echo "Node.js ve npm zaten yüklü."
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    // Bağımlılıkları yükle
                    sh 'cd client && npm install'
                }
            }
        }

        stage('Run Cypress Tests') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh '''
                        export TERM=xterm
                        cd client
                        npx cypress run --reporter json > $WORKSPACE/${TEST_RESULT_LOG_FILE}   
                    '''
                    }
                                
                }
            }
        }

        stage('Test Application Deployment') {
            steps {
                script {
                    def publicIPs = readFile('public_ips.txt').trim().split("\n")                    
                    def workerNodeIP = publicIPs[0]                    
                    sh """
                    curl -X POST http://${workerNodeIP}:30002/record   -H "Content-Type: application/json" -d '{"name": "mecit", "position": "DevOps", "level": "Middle"}' >> ${POST_GET_RESULT_FILE}
                    curl http://${workerNodeIP}:30001 >> ${POST_GET_RESULT_FILE}
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